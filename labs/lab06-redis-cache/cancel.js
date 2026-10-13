printjson(db.getSiblingDB("mobility").journey_search.updateMany(
    {_id: /^LAB05:/, "departures.tripId": "LAB05-T-OK"},
    {$set: {"departures.$[trip].status": "Cancelled"}},
    {arrayFilters: [{"trip.tripId": "LAB05-T-OK"}]},
));
