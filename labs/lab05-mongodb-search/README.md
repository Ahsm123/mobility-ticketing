# Lab 05 evidence

## 2. Search

### 1. Norreport to Airport, 06:00 to 07:00

```js
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
```

### 2. End at 06:20

```js
[]
```

### 3. Start at 06:20

```js
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
```

### 4. Airport to Norreport

```js
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
```

### 5. Same search on 3 Oct.

Same is ambigious, same as last or base? Last = `[]`

From base:

```js
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
```

### 6. Destination STOP-NO-MATCH

```js
[]
```

### 7. Empty stop id

```js
stopId = ""
```

```
Error: stopId cant be null
```

### 8. End after start

```js
const start = ISODate("2026-10-03T06:00:00Z");
const end = ISODate("2026-10-03T05:00:00Z");
```

```
Error: end cant be before start
```

## 3. Search bug

```js
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

printjson(m.journey_search.find(query).toArray())
```

Output:

```js
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
```

## 4. Updating duplicated data

### First update

```js
{ acknowledged: true, insertedId: null, matchedCount: 2, modifiedCount: 2, upsertedCount: 0 }
```

### Second update

```js
{ acknowledged: true, insertedId: null, matchedCount: 2, modifiedCount: 0, upsertedCount: 0 }
```

- Filteret leder kun efter tripId og ikke status så det matcher stadig begge dokumenter
- Modified er 0, fordi query prøver at ændre "Cancelled" til "Cancelled"
- Updating er idempotent

### Ændrer updates til LAB05:A

```js
{ acknowledged: true, insertedId: null, matchedCount: 1, modifiedCount: 1, upsertedCount: 0 }
```

Search.js med Norre-Air:

```js
[]
```

Search.js med Norre-Cent:

```js
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
```

- Trip er aflyst i A og ikke i C, fordi vi i anden update brugte "^LAB05:A"
- T-OK er i både A og C, derfor uenigheden nu.
- Efter update med "^LAB05:" giver anden Norre-Cent nu: `[]`

### 4.3 Move departure

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

- Nørreport - Airport, 06:00–07:00: `[]`
- Nørreport - Airport, 07:00–08:00: LAB05-T-EDGE (07:00), LAB05-T-OK (07:05–07:25)
- Nørreport - Central, 07:00–08:00: LAB05-T-OK (07:05–07:25)

Begge kopier (A og C) er flyttet. T-EDGE kommer med fordi starten af intervallet er inklusiv.

### Change the displayed price

Fixture resat før kørsel.

```js
m.journey_search.updateMany(
  {_id: /^LAB05:/, cityId: "CPH", routeId: "LINE-M2"},
  {$set: {price: Decimal128("40.00")}},
);
```

```js
{ acknowledged: true, matchedCount: 4, modifiedCount: 4, upsertedCount: 0 }
```

- A: CPH, LINE-M2, 40.00 DKK
- B: CPH, LAB-OTHER-ROUTE, 36.00 DKK
- C: CPH, LINE-M2, 40.00 DKK
- D: LAB-OTHER-CITY, LINE-M2, 36.00 DKK
- E: CPH, LINE-M2, 40.00 DKK
- F: CPH, LINE-M2, 40.00 DKK

D har en anden cityId og B har anden routeId. Line-M2 findes i flere byer, så routeId er kun unik per by.

## 5. Growth

```js
m.journey_search.insertOne(growth);
```

```js
{ bytes: 12307, departures: 100 }
{ bytes: 123007, departures: 1000 }
```

For at holde mængden nede:

- Størrelsen vokser lineært med antallet af afgange over tid, mongo har en grænse på 16MB pr. document, som ville være ~ 130081 (16000000/123)
- Ville ikke slette data, men rutinemæssigt flytte de afgange som er kørt til cold storage, så det ikke akkumulerer.
- Alternativt flytte dem til en anden collection efter de er kørt, så de ikke koster read compute når vi skal søge i dem.

Der er to spørgsmål her:

1. Hvad der skal flyttes, som er afgange der allerede er kørt.
2. Hvor tit det skal flyttes, afhænger af hvor hurtigt afgangene ophober sig.

## 6. One departure per document

Output fra search_alternative.js på den nye collection:

```js
{
  cityId: 'CPH',
  routeId: 'LINE-M2',
  fromStopId: 'STOP-NORREPORT',
  toStopId: 'STOP-AIRPORT',
  price: Decimal128('36.00'),
  currency: 'DKK',
  tripId: 'LAB05-T-EDGE',
  departureUtc: ISODate('2026-10-02T07:00:00.000Z'),
  arrivalUtc: ISODate('2026-10-02T07:20:00.000Z'),
  availableSeats: 10
}
```

### Testcases

1.

```js
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
```

2.

```js
[]
```

3.

```js
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
```

4.

```js
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
```

5.

```js
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
```

6.

```js
[]
```

### Opdatering af LAB05-T-OK

```js
const m = db.getSiblingDB("mobility");

printjson(
  m.journey_search_by_trip.updateMany(
    {tripId: 'LAB05-T-OK'},
    {$set: {status: "Cancelled"}},
  ),
);
```

```js
{ acknowledged: true, insertedId: null, matchedCount: 2, modifiedCount: 2, upsertedCount: 0 }
```

Før split skulle der opdateres 2 docs, A og C, og det var på et element i et Array.
Efter skal der stadig opdateres 2 docs, men feltet kan opdateres direkte.

Der er stadig 2, fordi man kan finde samme departure på forskellige destinationer.

## 7. Compare the two models

- Den alternative model fjernede behovet for `$unwind` og nesting på departures.
- Der bliver noget duplikering af det data der lå på journey niveau, men resten er det samme.
- Opdateringen af en departure er den samme, da den også var flere steder i model 1, dog skal der opdateres mere på journey, men det skulle være trivielt med `updateMany`.
- Collection fylder mere i model 2, men nu vokser ét dokument ikke ubegrænset, der kommer bare flere.
- Derudover er det også nemmere at flytte departures når de er kørt, fordi vi kan filtrere på `departureUtc` direkte, og ikke skal gøre det på arrays.

### Valg

Model 2, fordi den ikke rammer 16 MB loftet, og fordi den er simplere at arbejde med. Vi har en strategi for at håndtere pladsen, derfor er den ekstra kompleksitet ikke det værd.
