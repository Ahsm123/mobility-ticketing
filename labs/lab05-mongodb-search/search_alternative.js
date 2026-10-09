const m = db.getSiblingDB("mobility");

const start = ISODate("2026-10-02T06:00:00Z");
const end = ISODate("2026-10-02T07:00:00Z");
const fromStop = "STOP-NORREPORT";
const toStop = "STOP-AIRPORT";
const city = "CPH";

function search(cityId, fromStopId, toStopId, start, end) {
    if (end <= start) {
        throw new Error("end cant be before start")
    }
    if (!fromStopId || !toStopId) {
        throw new Error("stopId cant be null")
    }
    return m.journey_search_by_trip
        .aggregate([
            {
                $match: {cityId, fromStopId, toStopId},
            },
            {
                $match: {
                    status: "Scheduled",
                    departureUtc: {$gte: start, $lt: end},
                }
            },
            {
                $project: {
                    _id: 0,
                    cityId: true,
                    routeId: true,
                    fromStopId: true,
                    toStopId: true,
                    tripId: true,
                    departureUtc: true,
                    arrivalUtc: true,
                    availableSeats: true,
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

printjson(search(city, fromStop, toStop, start, end));
