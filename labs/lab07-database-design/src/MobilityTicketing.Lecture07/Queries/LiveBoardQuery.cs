using Microsoft.EntityFrameworkCore;
using MobilityTicketing.Lecture07.Data;
using MobilityTicketing.Lecture07.Contracts;

namespace MobilityTicketing.Lecture07.Queries;

public class LiveBoardQuery
{
    public static async Task<List<RouteOverviewDto>> ExecuteAsync(LectureDbContext db, DateTime fromUtc, DateTime toUtc, CancellationToken ct = default)
    {
        LabWindow.Validate(fromUtc, toUtc);
        var routes = await db.Routes
            .OrderBy(r => r.Id)    
            .Select(r => new RouteOverviewDto(
                r.Id,
                r.Name,
                r.Trips.Where(t => t.Status == "Scheduled" && t.DepartureUtc >= fromUtc && t.DepartureUtc < toUtc).Count(),
                r.Trips.Where(t => t.Status == "Scheduled" && t.DepartureUtc >= fromUtc && t.DepartureUtc < toUtc).Min(t => t.DepartureUtc)))
            .ToListAsync(ct);
        return routes;
    }
}


/*
 select r.id as "Route", r.short_name as "Name",
    count(t.id) as "Count",
    min(t.scheduled_departure_utc) as "Next UTC"
from routes r
left join trips t
    on t.route_id = r.id
    and t.scheduled_departure_utc >= 	'2026-10-23T06:00:00Z'
    and t.scheduled_departure_utc < '	2026-10-23T07:00:00Z'
    and t.status = 'Scheduled'
group by r.id
order by r.id;
*/
