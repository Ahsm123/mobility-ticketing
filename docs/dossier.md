# Assumptions:

1. A route can contain the same stop multiple times, but never two times in a row.

2. On busses and trams users can validate their own tickets when onboarding, on trains the operators validates on demand.

# Functional dependency

1. FD i route_stops: route_id, stop_sequence -> stop_id.
    Because a a position on a route determines a stop, and cant be done in reverse, so route_id, stop_id cant determine stop_sequence, because we assume that a route can contain the same stop multiple times.

    Normalization prevents that a non key attribute is dependent on another non-key. If stop_name and stop_id where both in route_stops, stop_name would be dependant on stop_id, and the stop_name would be repeated on every row in route_stops.
