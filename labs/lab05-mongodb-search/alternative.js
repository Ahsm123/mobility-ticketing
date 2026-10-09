const m = db.getSiblingDB("mobility");

if (!m.getCollectionNames().includes("journey_search_by_trip")) {
    m.createCollection("journey_search_by_trip");
} else {
    m.journey_search_by_trip.deleteMany({
        $or: [
            {_id: /^LAB05:/},
            {tripId: /^LAB05-/},
        ],
    });
}

const journeys = m.journey_search.find({_id: /^LAB05:/}).toArray();

//m.journey_search_by_trip.createIndex({ "cityId": 1, "routeId": 1, "fromStopId": 1, "toStopId": 1, "tripId":1 }, { unique: true });
// gav ikke deterministisk id hver gang, men tog ObjectId


for (const journey of journeys) {
    for (const departure of journey.departures) {
        var doc = {
            _id: `${journey.cityId}-${journey.routeId}-${journey.fromStopId}-${journey.toStopId}-${departure.tripId}`,
            schemaVersion: journey.schemaVersion,
            cityId: journey.cityId,
            routeId: journey.routeId,
            fromStopId: journey.fromStopId,
            toStopId: journey.toStopId,
            price: journey.price,
            currency: journey.currency,
            tripId: departure.tripId,
            departureUtc: departure.departureUtc,
            arrivalUtc: departure.arrivalUtc,
            availableSeats: departure.availableSeats,
            status: departure.status,
        }

        m.journey_search_by_trip.insertOne(doc);
    }
}
