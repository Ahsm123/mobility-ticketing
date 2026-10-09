using System.Text.Json;
using StackExchange.Redis;

public record CacheEntry(int SchemaVersion, DateTimeOffset? CachedAtUtc, List<Journey?>? Items);

public class CachedJourneySearch(MongoJourneySearch source, IDatabase redis, TimeSpan ttl)
{
    const int SchemaVersion = 2;
    static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);

    public async Task<List<Journey>> Search(SearchRequest request)
    {
        var key = CacheKey.Build(request);
        var cacheAvailable = true;

        try
        {
            var cached = await redis.StringGetAsync(key);
            if (cached.IsNull)
            {
                Console.WriteLine("miss");
            }
            else if (ReadCache(cached!) is { } items)
            {
                Console.WriteLine("hit");
                return items;
            }
            else
            {
                Console.WriteLine("invalid");
            }
        }
        catch (Exception ex) when (ex is RedisException or TimeoutException)
        {
            Console.WriteLine("cache unavailable");
            cacheAvailable = false;
        }

        List<Journey> result;
        try
        {
            result = await source.Fetch(request);
        }
        catch (Exception ex)
        {
            throw new InvalidOperationException("search error: MongoDB search failed", ex);
        }

        // Redis just failed on read, so a write would most likely only add another wait.
        if (!cacheAvailable)
            return result;

        try
        {
            var entry = new CacheEntry(SchemaVersion, DateTimeOffset.UtcNow, result!);
            await redis.StringSetAsync(key, JsonSerializer.Serialize(entry, Json), ttl);
        }
        catch (Exception ex) when (ex is RedisException or TimeoutException)
        {
            Console.WriteLine("cache write failed");
        }

        return result;
    }

    // Returns null when the cached value is not a valid cache entry.
    static List<Journey>? ReadCache(string value)
    {
        try
        {
            var entry = JsonSerializer.Deserialize<CacheEntry>(value, Json);
            if (entry is not { SchemaVersion: SchemaVersion, CachedAtUtc: not null, Items: not null })
                return null;
            if (entry.Items.Any(j => j is null))
                return null;
            return entry.Items!;
        }
        catch (JsonException)
        {
            return null;
        }
    }
}
