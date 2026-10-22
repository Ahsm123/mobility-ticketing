namespace MobilityTicketing.Lecture07.Data;

public class SnapshotHeader
{
    public string PlanId { get; set; } = "";
    public DateTime FromUtc { get; set; }
    public DateTime ToUtc { get; set; }
    public DateTime PublishedAt { get; set; }
}
