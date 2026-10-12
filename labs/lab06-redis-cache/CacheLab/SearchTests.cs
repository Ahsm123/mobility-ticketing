using System.Diagnostics;
using StackExchange.Redis;

// Section 4: test the cached search.
public class SearchTests(
    CachedJourneySearch cachedSearch,
    MongoJourneySearch source,
    IDatabase redis,
    SearchRequest request)
{
    public record TestRun(string Key, string DataSource, List<string> TripIds, int MongoCalls, long ElapsedMs);

    // Test A: repeat a search. Expect MongoDB first, then Redis with no extra MongoDB call.
    public async Task TestA()
    {
        var key = CacheKey.Build(request);
        await redis.KeyDeleteAsync(key);

        var firstRun = await Run(key);
        var secondRun = await Run(key);

        Console.WriteLine("Test A: repeat a search");
        PrintTest(firstRun);
        PrintTest(secondRun);
    }

    // Test B: cache an empty result. Expect second request is a cache hit with [].
    public async Task TestB()
    {
        var key = CacheKey.Build(request);
        await redis.KeyDeleteAsync(key);

        var firstRun = await Run(key);
        var secondRun = await Run(key);

        Console.WriteLine("Test B: cache empty result");
        PrintTest(firstRun);
        PrintTest(secondRun);
    }

    // Test C: expire a result. Expect MongoDB, then Redis with a TTL, then after expiry MongoDB again
    // and a new TTL. Needs a short-TTL cachedSearch (2 s), so the 5 s wait outlasts it.
    public async Task TestC()
    {
        var key = CacheKey.Build(request);
        await redis.KeyDeleteAsync(key);

        var firstRun = await Run(key);
        var secondRun = await Run(key);
        var ttlBeforeWait = await redis.KeyTimeToLiveAsync(key);

        await Task.Delay(TimeSpan.FromSeconds(5));

        var thirdRun = await Run(key);
        var ttlAfterExpiry = await redis.KeyTimeToLiveAsync(key);

        Console.WriteLine("Test C: expire a result");
        PrintTest(firstRun);
        PrintTest(secondRun);
        Console.WriteLine($"TTL: {ttlBeforeWait?.ToString() ?? "none"}");
        Console.WriteLine("waited 5 s");
        PrintTest(thirdRun);
        Console.WriteLine($"TTL: {ttlAfterExpiry?.ToString() ?? "none"}");
    }

    // Test D: store an invalid value. Expect "invalid" + MongoDB, then Redis: the bad value was replaced.
    public async Task TestD()
    {
        var key = CacheKey.Build(request);
        var invalidValues = new[]
        {
            ("not JSON", "not-json"),
            ("wrong schemaVersion", """{"schemaVersion":1,"cachedAtUtc":"2026-10-12T10:00:00+00:00","items":[]}"""),
            ("missing items", """{"schemaVersion":2,"cachedAtUtc":"2026-10-12T10:00:00+00:00"}""")
        };

        Console.WriteLine("Test D: store an invalid value");
        foreach (var (name, value) in invalidValues)
        {
            await redis.StringSetAsync(key, value, TimeSpan.FromSeconds(20));
            Console.WriteLine($"case: {name}");
            PrintTest(await Run(key));
            PrintTest(await Run(key));
        }
    }

    private async Task<TestRun> Run(string key)
    {
        var callsBefore = source.Calls;
        var stopwatch = Stopwatch.StartNew();
        var (items, dataSource) = await cachedSearch.Search(request);
        stopwatch.Stop();
        var tripIds = items.Select(j => j.TripId).ToList();
        return new TestRun(key, dataSource, tripIds, source.Calls - callsBefore, stopwatch.ElapsedMilliseconds);
    }

    static void PrintTest(TestRun run) =>
        Console.WriteLine($"key: {run.Key}, source: {run.DataSource}, trips: [{string.Join(", ", run.TripIds)}], " +
                          $"MongoDB calls: {run.MongoCalls}, time: {run.ElapsedMs} ms");
}