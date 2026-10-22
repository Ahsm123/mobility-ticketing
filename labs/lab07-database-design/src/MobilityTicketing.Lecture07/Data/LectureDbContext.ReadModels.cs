using Microsoft.EntityFrameworkCore;

namespace MobilityTicketing.Lecture07.Data;

public partial class LectureDbContext
{
    public DbSet<SnapshotHeader> SnapshotHeaders => Set<SnapshotHeader>();
    public DbSet<SnapshotRow> SnapshotRows => Set<SnapshotRow>();

    partial void ConfigureReadModels(ModelBuilder b)
    {
        b.Entity<SnapshotHeader>(e =>
        {
            e.ToTable("snapshot_header");
            e.HasKey(x => x.PlanId);
            e.Property(x => x.PlanId).HasColumnName("plan_id");
            e.Property(x => x.FromUtc).HasColumnName("from_utc");
            e.Property(x => x.ToUtc).HasColumnName("to_utc");
            e.Property(x => x.PublishedAt).HasColumnName("published_at_utc");
        });
        b.Entity<SnapshotRow>(e =>
        {
            e.ToTable("snapshot_rows");
            e.HasKey(x => new { x.PlanId, x.RouteId });
            e.Property(x => x.PlanId).HasColumnName("plan_id");
            e.Property(x => x.RouteId).HasColumnName("route_id");
            e.Property(x => x.RouteName).HasColumnName("route_name");
            e.Property(x => x.Count).HasColumnName("count");
            e.Property(x => x.NextDeparture).HasColumnName("next_departure_utc");
        });
    }
}
