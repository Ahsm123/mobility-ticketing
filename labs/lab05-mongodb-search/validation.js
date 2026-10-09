const m = db.getSiblingDB("mobility");

const doc1 = m.journey_search.findOne({ _id: "LAB05:A"});
doc1.departures[0].departureUtc = '2026-10-02T05:50:00.000Z';

try{
    m.journey_search.insertOne(doc1);
    print("doc1 insert was accepted");
} catch (ex) {
    print("doc1 rejected with code " + ex.code)
}

const doc2 = m.journey_search.findOne({ _id: "LAB05:B"});
doc2.departures[0].availableSeats = -1;

try{
    m.journey_search.insertOne(doc2);
    print("doc2 insert was accepted");
} catch (ex) {
    print("doc2 rejected with code " + ex.code)
}

// doc1 rejected with code 121
// doc2 rejected with code 121