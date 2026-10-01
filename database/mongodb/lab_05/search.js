const m = db.getSiblingDB("mobility");

const start = ISODate("2026-10-02T07:00:00Z");
const end = ISODate("2026-10-02T08:00:00Z");

function search(cityId, fromStopId, toStopId, start, end) {
    if (end <= start) {
        throw new Error("end cant be before start")
    }
    if (!fromStopId || !toStopId) {
        throw new Error("stopId cant be null")
    }
    return m.journey_search
        .aggregate([
            {
                $match: {cityId, fromStopId, toStopId},
            },
            {
                $unwind: "$departures"
            },
            {
                $match: {
                    "departures.status": "Scheduled",
                    "departures.departureUtc": {$gte: start, $lt: end},
                }
            },
            {
                $project: {
                    _id: 0,
                    cityId: true,
                    routeId: true,
                    fromStopId: true,
                    toStopId: true,
                    tripId: "$departures.tripId",
                    departureUtc: "$departures.departureUtc",
                    arrivalUtc: "$departures.arrivalUtc",
                    availableSeats: "$departures.availableSeats",
                    price: true,
                    currency: true,
                }
            },
            {
                $sort: {
                    departureUtc: 1
                }
            }
        ])
        .toArray();
}

printjson(search("CPH", "STOP-NORREPORT", "STOP-AIRPORT", start, end));
