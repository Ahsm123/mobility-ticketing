const m = db.getSiblingDB("mobility");
const start = ISODate("2026-10-02T06:00:00Z");
const end = ISODate("2026-10-02T07:00:00Z");

const query = {
    cityId: "CPH",
    fromStopId: "STOP-NORREPORT",
    toStopId: "STOP-AIRPORT",
    departures: {
        $elemMatch: {status: "Scheduled", departureUtc: {$gte: start, $lt: end}}
    }
    // TODO: add departures.departureUtc
    // as a separate condition.
};

printjson(m.journey_search.find(query).toArray()
)

// B1 matchede status, B2 matchede tiden
// elemMatch kræver at en departure matcher begge