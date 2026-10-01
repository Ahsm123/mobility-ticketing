const m = db.getSiblingDB("mobility");

printjson(
    m.journey_search.updateMany(
        {
            _id: /^LAB05:/,
            cityId: "CPH",
            routeId: "LINE-M2",
        },
        {
            $set: {
                "price": Decimal128('40.00'),
            },
        },
    ),
);
