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

# Updating duplicated data

- First update
  {
  acknowledged: true,
  insertedId: null,
  matchedCount: 2,
  modifiedCount: 2,
  upsertedCount: 0
  }
- Second update
  {
  acknowledged: true,
  insertedId: null,
  matchedCount: 2,
  modifiedCount: 0,
  upsertedCount: 0
  }

- Filteret leder kun efter tripId og ikke status så det matcher stadig begge dokumenter
- Modified er 0, fordi query prøver at ændre "Cancelled" til "Cancelled"
- Updating er idempotent

- Ændrer updates til LAB05:A
  {
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
  }

- Search.js med Norre-Air
  []

- Search.js med Norre-Cent
  {
  cityId: 'CPH',
  routeId: 'LINE-M2',
  fromStopId: 'STOP-NORREPORT',
  toStopId: 'STOP-CENTRAL',
  price: Decimal128('36.00'),
  currency: 'DKK',
  tripId: 'LAB05-T-OK',
  departureUtc: ISODate('2026-10-02T06:20:00.000Z'),
  arrivalUtc: ISODate('2026-10-02T06:40:00.000Z'),
  availableSeats: 10
  }

- Trip er aflyst i A og ikke i C, fordi vi i anden update brugte "^LAB05:A"
- T-OK er i både A og C, derfor uenigheden nu.

- Efter update med "^LAB05:" giver anden Norre-Cent nu:
  []

## 4.3 Move departure

Fixture resat før kørsel.

```js
m.journey_search.updateMany(
    {_id: /^LAB05:/, "departures.tripId": "LAB05-T-OK"},
    {
        $set: {
            "departures.$[trip].departureUtc": ISODate("2026-10-02T07:05:00Z"),
            "departures.$[trip].arrivalUtc": ISODate("2026-10-02T07:25:00Z"),
        },
    },
    {arrayFilters: [{"trip.tripId": "LAB05-T-OK"}]},
);
```

| Søgning             | Interval    | Resultat                                       |
|---------------------|-------------|------------------------------------------------|
| Nørreport - Airport | 06:00–07:00 | `[]`                                           |
| Nørreport - Airport | 07:00–08:00 | LAB05-T-EDGE (07:00), LAB05-T-OK (07:05–07:25) |
| Nørreport - Central | 07:00–08:00 | LAB05-T-OK (07:05–07:25)                       |

Begge kopier (A og C) er flyttet. T-EDGE kommer med fordi starten af intervallet er inklusiv.

## Change the displayed price

Fixture resat før kørsel.

```js
m.journey_search.updateMany(
  { _id: /^LAB05:/, cityId: "CPH", routeId: "LINE-M2" },
  { $set: { price: Decimal128("40.00") } },
);
```

```
{ acknowledged: true, matchedCount: 4, modifiedCount: 4, upsertedCount: 0 }
```

| Dokument | cityId         | routeId         | Pris efter |
|----------|----------------|-----------------|------------|
| A        | CPH            | LINE-M2         | 40.00 DKK  |
| B        | CPH            | LAB-OTHER-ROUTE | 36.00 DKK  |
| C        | CPH            | LINE-M2         | 40.00 DKK  |
| D        | LAB-OTHER-CITY | LINE-M2         | 36.00 DKK  |
| E        | CPH            | LINE-M2         | 40.00 DKK  |
| F        | CPH            | LINE-M2         | 40.00 DKK  |

- D har en anden cityId og B har anden routeId
- Line-M2 findes i flere byer, så routeId er kun unik per by.
