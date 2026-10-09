const m = db.getSiblingDB("mobility");


const query = {
    _id: /^LAB05:/
};

printjson(m.journey_search.find(query).toArray()
)