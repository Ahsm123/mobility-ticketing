1. Norreport to Airport, 06:00 to 07:00
   {
   cityId: 'CPH',
   routeId: 'LINE-M2',
   fromStopId: 'STOP-NORREPORT',
   toStopId: 'STOP-AIRPORT',
   price: Decimal128('36.00'),
   currency: 'DKK',
   tripId: 'LAB05-T-OK',
   departureUtc: ISODate('2026-10-02T06:20:00.000Z'),
   arrivalUtc: ISODate('2026-10-02T06:40:00.000Z'),
   availableSeats: 10
   }

2. End at 06:20
   []

3. Start at 06:20
   {
   cityId: 'CPH',
   routeId: 'LINE-M2',
   fromStopId: 'STOP-NORREPORT',
   toStopId: 'STOP-AIRPORT',
   price: Decimal128('36.00'),
   currency: 'DKK',
   tripId: 'LAB05-T-OK',
   departureUtc: ISODate('2026-10-02T06:20:00.000Z'),
   arrivalUtc: ISODate('2026-10-02T06:40:00.000Z'),
   availableSeats: 10
   }

4. Airport to Norreport
   {
   cityId: 'CPH',
   routeId: 'LINE-M2',
   fromStopId: 'STOP-AIRPORT',
   toStopId: 'STOP-NORREPORT',
   price: Decimal128('36.00'),
   currency: 'DKK',
   tripId: 'LAB05-T-E',
   departureUtc: ISODate('2026-10-02T06:30:00.000Z'),
   arrivalUtc: ISODate('2026-10-02T06:50:00.000Z'),
   availableSeats: 10
   }

5. Same search on 3 Oct. (Same is ambigious, same as last or base? Last = [])
   From base:
   {
   cityId: 'CPH',
   routeId: 'LINE-M2',
   fromStopId: 'STOP-NORREPORT',
   toStopId: 'STOP-AIRPORT',
   price: Decimal128('36.00'),
   currency: 'DKK',
   tripId: 'LAB05-T-F',
   departureUtc: ISODate('2026-10-03T06:20:00.000Z'),
   arrivalUtc: ISODate('2026-10-03T06:40:00.000Z'),
   availableSeats: 10
   }

6. Destination STOP-NO-MATCH
   []

7. empty stop id
   stopId = ""
   Error: stopId cant be null

8. end after start
   const start = ISODate("2026-10-03T06:00:00Z");
   const end = ISODate("2026-10-03T05:00:00Z");

   Error: end cant be before start

## Search bug:

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

- Output:
  {
  _id: 'LAB05:A',
  cityId: 'CPH',
  routeId: 'LINE-M2',
  fromStopId: 'STOP-NORREPORT',
  toStopId: 'STOP-AIRPORT',
  serviceDate: '2026-10-02',
  schemaVersion: 1,
  price: Decimal128('36.00'),
  currency: 'DKK',
  departures: [
  {
  tripId: 'LAB05-T-EARLY',
  departureUtc: ISODate('2026-10-02T05:50:00.000Z'),
  arrivalUtc: ISODate('2026-10-02T06:10:00.000Z'),
  availableSeats: 10,
  status: 'Scheduled'
  },
  {
  tripId: 'LAB05-T-CANCEL',
  departureUtc: ISODate('2026-10-02T06:10:00.000Z'),
  arrivalUtc: ISODate('2026-10-02T06:30:00.000Z'),
  availableSeats: 10,
  status: 'Cancelled'
  },
  {
  tripId: 'LAB05-T-OK',
  departureUtc: ISODate('2026-10-02T06:20:00.000Z'),
  arrivalUtc: ISODate('2026-10-02T06:40:00.000Z'),
  availableSeats: 10,
  status: 'Scheduled'
  },
  {
  tripId: 'LAB05-T-EDGE',
  departureUtc: ISODate('2026-10-02T07:00:00.000Z'),
  arrivalUtc: ISODate('2026-10-02T07:20:00.000Z'),
  availableSeats: 10,
  status: 'Scheduled'
  }
  ]
  }

   