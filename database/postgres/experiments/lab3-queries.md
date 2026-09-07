SELECT routes.operator_id, SUM(amount)  
FROM payments 
    JOIN tickets ON payments.ticket_id = tickets.id 
    JOIN trips ON tickets.trip_id = trips.id 
    JOIN routes ON trips.route_id = routes.id 
WHERE DATE_TRUNC('day', payments.created_utc) = 
    CURRENT_DATE AND payments.status = 'Captured' GROUP BY(routes.operator_id)