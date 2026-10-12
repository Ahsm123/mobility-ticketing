// Section 2: the cache key separates different searches and joins equal ones.
public class KeyTests(SearchRequest request)
{
    public void Run()
    {
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
    }

    static void Check(string first, string second, string expected)
    {
        var actual = first == second ? "equal" : "not equal";
        Console.WriteLine($"Expected: {expected}.\nWas: {actual}");
    }
}
