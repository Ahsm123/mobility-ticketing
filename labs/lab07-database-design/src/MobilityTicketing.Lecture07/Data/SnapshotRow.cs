namespace MobilityTicketing.Lecture07.Data;

public class SnapshotRow
{
    public string PlanId { get; set; } = "";
    public string RouteId { get; set; } = "";
    public string RouteName { get; set; } = "";
    public int Count { get; set; }
    public DateTime? NextDeparture { get; set; }
}
