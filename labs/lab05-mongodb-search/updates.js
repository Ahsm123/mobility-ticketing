const m = db.getSiblingDB("mobility");

printjson(
    m.journey_search_by_trip.updateMany(
        {
            tripId: 'LAB05-T-OK'
        },
        {
            $set: {
                status: "Cancelled",
            },
        },
    ),
);
