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

Console.WriteLine("---------------------");
Console.WriteLine("Key Tests:");
Console.WriteLine("---------------------");
new KeyTests(request).Run();
Console.WriteLine("---------------------");
Console.WriteLine("Cache Tests:");
Console.WriteLine("---------------------");
await new CacheTests(cachedSearch, source, request).Run();
Console.WriteLine("---------------------");
Console.WriteLine("Search Tests:");
Console.WriteLine("---------------------");
await new SearchTests(cachedSearch, source, redis.GetDatabase(), request).TestA();

var emptyRequest = request with
{
    Start = DateTimeOffset.Parse("2026-10-05T18:00:00Z"),
    End = DateTimeOffset.Parse("2026-10-05T19:00:00Z")
};
await new SearchTests(cachedSearch, source, redis.GetDatabase(), emptyRequest).TestB();

var cachedSearchWithLowTtl = new CachedJourneySearch(source, redis.GetDatabase(), TimeSpan.FromSeconds(2));
await new SearchTests(cachedSearchWithLowTtl, source, redis.GetDatabase(), request).TestC();
await new SearchTests(cachedSearch, source, redis.GetDatabase(), request).TestD();

