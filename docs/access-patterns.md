
# Workload - Actor - Read/Write - Latency - Consistency

1. Journey Search - Customer - Read heavy - Low - Stale acceptable

2. Ticket Purchase - Customer - Read/Write - Seconds - Strong/Critical

3. Ticket Validation - Customer - Read/Write - Low - Strong
    a. For reporting Latency can be higher and consistency eventual.

4. Timetable Maintenance - Operator -  Write - N/A - Eventual

5. Real-time Availability - Both - Read/Write-heavy - Low - Good enough for search, and trustworthy enough to purchase.

6. Reporting - Operator - Heavy Read - Minutes? - Eventual
