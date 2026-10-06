namespace DefaultNamespace;

public static class CacheKey
{
    static string Part(string value) => ...;      // fra opgaven
    static string Instant(DateTimeOffset value) => ...; // fra opgaven

    public static string Build(SearchRequest q)
    {
        if (q is null)
        {
            return null;
        }
        
        return $"search:LAB06:v2:{Part(q.CityId)...}:{Part(q.FromStopId)}:{q.ToStopId}:{Instant(q.Start)}:{Instant(q.End)}";
    }
    
}