using System.Text.Json;

// Section 3: cache-aside around the MongoDB search.
public class CacheTests(CachedJourneySearch cachedSearch, MongoJourneySearch source, SearchRequest request)
{
    public async Task Run()
    {
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
                var (result, dataSource) = await cachedSearch.Search(search);
                var json = JsonSerializer.Serialize(result, new JsonSerializerOptions(JsonSerializerDefaults.Web));
                Console.WriteLine($"Result: {json}\nDatasource: {dataSource}");
            }
            catch (InvalidOperationException ex)
            {
                Console.WriteLine(ex.Message);
            }
            Console.WriteLine($"MongoDB calls: {source.Calls}, time: {stopwatch.ElapsedMilliseconds} ms");
        }
    }
}
