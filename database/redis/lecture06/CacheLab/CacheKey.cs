public static class CacheKey
{
    static string Part(string value) => Uri.EscapeDataString(value);
    static string Instant(DateTimeOffset value) =>
        value.UtcDateTime.ToString(
            "O",
            System.Globalization.CultureInfo.InvariantCulture);

    public static string Build(SearchRequest q)
    {
        ArgumentNullException.ThrowIfNull(q);
        ArgumentException.ThrowIfNullOrEmpty(q.CityId);
        ArgumentException.ThrowIfNullOrEmpty(q.FromStopId);
        ArgumentException.ThrowIfNullOrEmpty(q.ToStopId);
        if (q.Start >= q.End)
            throw new ArgumentException($"End ({q.End:O}) must be after Start ({q.Start:O}).", nameof(q));
        
        return $"search:LAB06:v2:{Part(q.CityId)}:{Part(q.FromStopId)}:{Part(q.ToStopId)}:{Instant(q.Start)}:{Instant(q.End)}";
    }
    
}