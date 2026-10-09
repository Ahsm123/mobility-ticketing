using System.Text.Json;
using StackExchange.Redis;

var options = ConfigurationOptions.Parse("127.0.0.1:6379");
options.AbortOnConnectFail = false;
options.ConnectTimeout = 500;
options.AsyncTimeout = 500;
options.ConnectRetry = 1;
// Fail commands immediately while disconnected instead of waiting in the backlog (~5 s).
options.BacklogPolicy = BacklogPolicy.FailFast;

using var redis = await ConnectionMultiplexer.ConnectAsync(options);
var source = new MongoJourneySearch();
var ttl = TimeSpan.FromSeconds(20);

var cachedSearch = new CachedJourneySearch(source, redis.GetDatabase(), ttl);
var request = new SearchRequest("CPH", "STOP-NORREPORT", "STOP-AIRPORT",
    DateTimeOffset.Parse("2026-10-02T06:00:00Z"),
    DateTimeOffset.Parse("2026-10-02T07:00:00Z"));

// Morning search (one result) and evening search (empty result), each twice:
// expect miss, then hit, with one MongoDB call per search.
var emptyRequest = request with
{
    Start = DateTimeOffset.Parse("2026-10-02T18:00:00Z"),
    End = DateTimeOffset.Parse("2026-10-02T19:00:00Z")
};
foreach (var search in new[] { request, request, emptyRequest, emptyRequest })
{
    var stopwatch = System.Diagnostics.Stopwatch.StartNew();
    try
    {
        var result = await cachedSearch.Search(search);
        Console.WriteLine(JsonSerializer.Serialize(result, new JsonSerializerOptions(JsonSerializerDefaults.Web)));
    }
    catch (InvalidOperationException ex)
    {
        Console.WriteLine(ex.Message);
    }
    Console.WriteLine($"MongoDB calls: {source.Calls}, time: {stopwatch.ElapsedMilliseconds} ms");
}

// Morning and evening searches
var morningKey = CacheKey.Build(request);
var evening = request with
{
    Start = DateTimeOffset.Parse("2026-10-02T18:00:00Z"),
    End = DateTimeOffset.Parse("2026-10-02T19:00:00Z")
};
var eveningKey = CacheKey.Build(evening);
Check(morningKey, eveningKey, "not equal");

// Origin and destination reversed
var reversedRequest = request with
{
    FromStopId = "STOP-AIRPORT",
    ToStopId = "STOP-NORREPORT"
};
Check(CacheKey.Build(request), CacheKey.Build(reversedRequest), "not equal");

// The same instant written as 06:00Z or 08:00+02:00
var timeZoneRequest = request with
{
    Start = DateTimeOffset.Parse("2026-10-02T08:00:00+02:00")
};
Check(CacheKey.Build(request), CacheKey.Build(timeZoneRequest), "equal");

// Stop pairs A:B / C and A / B:C
var reqAB = request with { FromStopId = "A:B", ToStopId = "C" };
var reqA = request with { FromStopId = "A", ToStopId = "B:C" };
Check(CacheKey.Build(reqAB), CacheKey.Build(reqA), "not equal");

static void Check(string first, string second, string expected)
{
    var actual = first == second ? "equal" : "not equal";
    Console.WriteLine($"Expected: {expected}.\nWas: {actual}");
}
