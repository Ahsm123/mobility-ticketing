# Assumptions:

1. A route can contain the same stop multiple times, but never two times in a row.

2. On busses and trams users can validate their own tickets when onboarding, on trains the operators validates on
   demand.

# Functional dependency

1. FD i route_stops: route_id, stop_sequence -> stop_id. Because a a position on a route determines a stop, and cant be
   done in reverse, so route_id, stop_id cant determine stop_sequence, because we assume that a route can contain the
   same stop multiple times.

   Normalization prevents that a non key attribute is dependent on another non-key. If stop_name and stop_id where both
   in route_stops, stop_name would be dependent on stop_id, and the stop_name would be repeated on every row in
   route_stops.

# Rules

1. (A) Capacity cannot be negative
2. (A) Reserved seats cannot be negative or > capacity
3. (A) Prices and payment amounts ! negative
4. (A)+ (C) A Ticket must reference existing: User, Trip, Product
5. (A)+ (C) A payment must reference an existing ticket
6. (A)+ (C) Validations must reference existing tickets
7. (B) Ticket codes must be unique
8. (A) Ticket validity cant end before it begins
9. (A) Status values must come from a set (enums)
10. (B) External payments references must not accidentally represent the same payment more than once.
11. (A) A users email must be unique
12. (B) A used ticket cannot be validated again
13. (A) Products, Tickets and Payments must have a valid currency.

A: Can true/false be validated from the row = check, not null B: Do i need to look at other rows in the same table =
unique, create unique index C: Do i need to look in another table for the value? = foreign key D: Do i need to calculate
or aggregate or know anything outside the db? = code

# Decisions
1. Context: payments status
   Decision: changes to: failed, captured, refunded to reflect the labs implementation
   Alternatives: had pending, authorized and canceled before, but no need to guess future implementation
   Consequences: cant express payments state in flight. Payment can only be done not intermediate state.