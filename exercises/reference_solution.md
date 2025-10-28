# Reference Implementation - Instructor's Solution

## Keyspace Setup

```cql
CREATE KEYSPACE IF NOT EXISTS bikeshare
WITH REPLICATION = {
    'class': 'NetworkTopologyStrategy',
    'datacenter1': 3
};
```

**Best Practice**: Always prefix table names with keyspace (`keyspace.table`)

---

## Q1: bikes_by_station (Using SAI Index)

**Query Pattern**: Find all available bikes at a specific station, ordered by last maintenance date

### Table Definition

```cql
CREATE TABLE IF NOT EXISTS bikeshare.bikes_by_station (
    station_id UUID,
    last_maintenance_date DATE,
    bike_id UUID,
    model TEXT,
    bike_type TEXT,
    battery_level INT,
    status TEXT,
    PRIMARY KEY ((station_id), last_maintenance_date, bike_id)
) WITH CLUSTERING ORDER BY (last_maintenance_date DESC, bike_id ASC)
AND comment = 'Q1: Available bikes at station ordered by maintenance date';

-- SAI index on status for flexible filtering within partition
CREATE INDEX IF NOT EXISTS bikes_status_sai_idx 
ON bikeshare.bikes_by_station(status) 
USING 'sai';
```

**Design Rationale:**
- Partition Key: `station_id` (query by station)
- Clustering Columns: `last_maintenance_date DESC`, `bike_id`
- SAI Index on `status`: Enables filtering without ALLOW FILTERING
- Single-partition reads (fast!)

### Sample Data

```cql
INSERT INTO bikeshare.bikes_by_station (station_id, last_maintenance_date, bike_id, 
    model, bike_type, battery_level, status)
VALUES (11111111-1111-1111-1111-111111111111, '2025-10-25', 
    aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa, 'Urban Cruiser X1', 'standard', null, 'available');

INSERT INTO bikeshare.bikes_by_station (station_id, last_maintenance_date, bike_id, 
    model, bike_type, battery_level, status)
VALUES (11111111-1111-1111-1111-111111111111, '2025-10-24', 
    bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb, 'E-Bike Pro 3000', 'electric', 95, 'available');

INSERT INTO bikeshare.bikes_by_station (station_id, last_maintenance_date, bike_id, 
    model, bike_type, battery_level, status)
VALUES (11111111-1111-1111-1111-111111111111, '2025-10-20', 
    cccccccc-cccc-cccc-cccc-cccccccccccc, 'Urban Cruiser X2', 'standard', null, 'available');

INSERT INTO bikeshare.bikes_by_station (station_id, last_maintenance_date, bike_id, 
    model, bike_type, battery_level, status)
VALUES (11111111-1111-1111-1111-111111111111, '2025-10-18', 
    12345678-1234-1234-1234-123456789012, 'Urban Cruiser X1', 'standard', null, 'in_maintenance');

INSERT INTO bikeshare.bikes_by_station (station_id, last_maintenance_date, bike_id, 
    model, bike_type, battery_level, status)
VALUES (22222222-2222-2222-2222-222222222222, '2025-10-26', 
    dddddddd-dddd-dddd-dddd-dddddddddddd, 'Student Special', 'standard', null, 'available');
```

### Example Queries

```cql
-- Get all bikes at station
SELECT bike_id, model, bike_type, battery_level, last_maintenance_date, status
FROM bikeshare.bikes_by_station
WHERE station_id = 11111111-1111-1111-1111-111111111111;
-- Expected: 4 bikes ordered by date DESC

-- Get ONLY available bikes (using SAI)
SELECT bike_id, model, bike_type, battery_level, last_maintenance_date, status
FROM bikeshare.bikes_by_station
WHERE station_id = 11111111-1111-1111-1111-111111111111
  AND status = 'available';
-- Expected: 3 bikes - NO ALLOW FILTERING needed!

-- Get bikes in maintenance
SELECT bike_id, model, last_maintenance_date
FROM bikeshare.bikes_by_station
WHERE station_id = 11111111-1111-1111-1111-111111111111
  AND status = 'in_maintenance';
-- Expected: 1 bike

-- Recently maintained available bikes
SELECT bike_id, model, last_maintenance_date
FROM bikeshare.bikes_by_station
WHERE station_id = 11111111-1111-1111-1111-111111111111
  AND last_maintenance_date >= '2025-10-20'
  AND status = 'available';
-- Expected: 3 bikes (combines clustering + SAI)
```

---

## Q2: rentals_by_user_month

**Query Pattern**: Get rental history for a user for a specific month

### Table Definition

```cql
CREATE TABLE IF NOT EXISTS bikeshare.rentals_by_user_month (
    user_id UUID,
    rental_month TEXT,
    start_time TIMESTAMP,
    rental_id UUID,
    bike_id UUID,
    start_station_name TEXT,
    end_station_name TEXT,
    duration_minutes INT,
    cost DECIMAL,
    PRIMARY KEY ((user_id, rental_month), start_time, rental_id)
) WITH CLUSTERING ORDER BY (start_time DESC, rental_id ASC)
AND comment = 'Q2: User rental history with monthly bucketing';
```

**Design Rationale:**
- Compound Partition Key: `(user_id, rental_month)` prevents unbounded growth
- Time Bucketing: 'YYYY-MM' format keeps partitions bounded
- Denormalization: Station names included for fast reads

### Sample Data

```cql
INSERT INTO bikeshare.rentals_by_user_month (user_id, rental_month, start_time, rental_id,
    bike_id, start_station_name, end_station_name, duration_minutes, cost)
VALUES (
    99999999-9999-9999-9999-999999999999, '2025-10',
    '2025-10-27 08:15:00+0000', 77777777-7777-7777-7777-777777777777,
    aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa,
    'Downtown Hub', 'University Campus', 30, 3.50
);

INSERT INTO bikeshare.rentals_by_user_month (user_id, rental_month, start_time, rental_id,
    bike_id, start_station_name, end_station_name, duration_minutes, cost)
VALUES (
    99999999-9999-9999-9999-999999999999, '2025-10',
    '2025-10-26 17:30:00+0000', 88888888-8888-8888-8888-888888888888,
    bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb,
    'University Campus', 'Downtown Hub', 45, 4.75
);

INSERT INTO bikeshare.rentals_by_user_month (user_id, rental_month, start_time, rental_id,
    bike_id, start_station_name, end_station_name, duration_minutes, cost)
VALUES (
    99999999-9999-9999-9999-999999999999, '2025-10',
    '2025-10-25 12:00:00+0000', 66666666-6666-6666-6666-666666666666,
    cccccccc-cccc-cccc-cccc-cccccccccccc,
    'Downtown Hub', 'Park Station', 25, 2.50
);
```

### Example Queries

```cql
-- Get October 2025 rental history
SELECT start_time, start_station_name, end_station_name, duration_minutes, cost
FROM bikeshare.rentals_by_user_month
WHERE user_id = 99999999-9999-9999-9999-999999999999
  AND rental_month = '2025-10';
-- Expected: 3 rentals ordered DESC (Oct 27, 26, 25)
```

---

## Q3: stations

**Query Pattern**: Get detailed information about a specific station

### Table Definition

```cql
CREATE TABLE IF NOT EXISTS bikeshare.stations (
    station_id UUID PRIMARY KEY,
    station_name TEXT,
    city TEXT,
    latitude DECIMAL,
    longitude DECIMAL,
    total_docks INT,
    available_bikes INT,
    postal_code TEXT
) WITH comment = 'Q3: Station information lookup';
```

### Sample Data

```cql
INSERT INTO bikeshare.stations (station_id, station_name, city, latitude, longitude, 
    total_docks, available_bikes, postal_code)
VALUES (11111111-1111-1111-1111-111111111111, 'Downtown Hub', 'San Francisco',
    37.7749, -122.4194, 15, 3, '94102');

INSERT INTO bikeshare.stations (station_id, station_name, city, latitude, longitude,
    total_docks, available_bikes, postal_code)
VALUES (22222222-2222-2222-2222-222222222222, 'University Campus', 'San Francisco',
    37.7699, -122.4469, 20, 5, '94117');

INSERT INTO bikeshare.stations (station_id, station_name, city, latitude, longitude,
    total_docks, available_bikes, postal_code)
VALUES (33333333-3333-3333-3333-333333333333, 'Park Station', 'San Francisco',
    37.7694, -122.4862, 12, 8, '94122');
```

### Example Queries

```cql
-- Get station details
SELECT station_name, city, available_bikes, total_docks, latitude, longitude
FROM bikeshare.stations
WHERE station_id = 11111111-1111-1111-1111-111111111111;
-- Expected: 1 row

-- Update available bikes
UPDATE bikeshare.stations
SET available_bikes = 4
WHERE station_id = 11111111-1111-1111-1111-111111111111;
```

---

## Q4: stations_by_city

**Query Pattern**: Find all stations in a city

### Table Definition

```cql
CREATE TABLE IF NOT EXISTS bikeshare.stations_by_city (
    city TEXT,
    station_id UUID,
    station_name TEXT,
    latitude DECIMAL,
    longitude DECIMAL,
    available_bikes INT,
    total_docks INT,
    PRIMARY KEY ((city), station_name, station_id)
) WITH CLUSTERING ORDER BY (station_name ASC, station_id ASC)
AND comment = 'Q4: Stations grouped by city';
```

### Sample Data

```cql
INSERT INTO bikeshare.stations_by_city (city, station_id, station_name, latitude, longitude,
    available_bikes, total_docks)
VALUES ('San Francisco', 11111111-1111-1111-1111-111111111111, 'Downtown Hub',
    37.7749, -122.4194, 3, 15);

INSERT INTO bikeshare.stations_by_city (city, station_id, station_name, latitude, longitude,
    available_bikes, total_docks)
VALUES ('San Francisco', 33333333-3333-3333-3333-333333333333, 'Park Station',
    37.7694, -122.4862, 8, 12);

INSERT INTO bikeshare.stations_by_city (city, station_id, station_name, latitude, longitude,
    available_bikes, total_docks)
VALUES ('San Francisco', 22222222-2222-2222-2222-222222222222, 'University Campus',
    37.7699, -122.4469, 5, 20);
```

### Example Queries

```cql
-- Get all stations in San Francisco
SELECT station_name, latitude, longitude, available_bikes, total_docks
FROM bikeshare.stations_by_city
WHERE city = 'San Francisco';
-- Expected: 3 stations alphabetically ordered
```

---

## Q5: maintenance_by_bike

**Query Pattern**: Get maintenance history for a bike

### UDT and Table Definition

```cql
CREATE TYPE IF NOT EXISTS bikeshare.parts_info (
    part_name TEXT,
    part_cost DECIMAL,
    quantity INT
);

CREATE TABLE IF NOT EXISTS bikeshare.maintenance_by_bike (
    bike_id UUID,
    maintenance_date TIMESTAMP,
    maintenance_id UUID,
    technician_name TEXT,
    issue_description TEXT,
    parts_replaced LIST<FROZEN<parts_info>>,
    total_cost DECIMAL,
    PRIMARY KEY ((bike_id), maintenance_date, maintenance_id)
) WITH CLUSTERING ORDER BY (maintenance_date DESC, maintenance_id ASC)
AND comment = 'Q5: Maintenance history per bike with UDT';
```

### Sample Data

```cql
INSERT INTO bikeshare.maintenance_by_bike (bike_id, maintenance_date, maintenance_id,
    technician_name, issue_description, parts_replaced, total_cost)
VALUES (
    aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa,
    '2025-10-25 14:30:00+0000',
    55555555-5555-5555-5555-555555555551,
    'Mike Rodriguez',
    'Regular maintenance - brake adjustment',
    [{part_name: 'Brake Pads', part_cost: 15.99, quantity: 2}],
    15.99
);

INSERT INTO bikeshare.maintenance_by_bike (bike_id, maintenance_date, maintenance_id,
    technician_name, issue_description, parts_replaced, total_cost)
VALUES (
    aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa,
    '2025-09-15 11:00:00+0000',
    55555555-5555-5555-5555-555555555552,
    'Sarah Chen',
    'Chain replacement and gear adjustment',
    [{part_name: 'Chain', part_cost: 24.99, quantity: 1},
     {part_name: 'Chain Lubricant', part_cost: 8.99, quantity: 1}],
    33.98
);

INSERT INTO bikeshare.maintenance_by_bike (bike_id, maintenance_date, maintenance_id,
    technician_name, issue_description, parts_replaced, total_cost)
VALUES (
    bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb,
    '2025-10-24 09:15:00+0000',
    55555555-5555-5555-5555-555555555553,
    'Mike Rodriguez',
    'Battery replacement and software update',
    [{part_name: 'Lithium Battery', part_cost: 89.99, quantity: 1}],
    89.99
);
```

### Example Queries

```cql
-- Get all maintenance history for bike
SELECT maintenance_date, technician_name, issue_description, parts_replaced, total_cost
FROM bikeshare.maintenance_by_bike
WHERE bike_id = aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa
ORDER BY maintenance_date DESC;
-- Expected: 2 records (Oct 25, Sep 15)

-- Get recent maintenance only
SELECT maintenance_date, issue_description, total_cost
FROM bikeshare.maintenance_by_bike
WHERE bike_id = aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa
  AND maintenance_date >= '2025-10-01 00:00:00+0000';
-- Expected: 1 record (Oct 25)
```

---

## Q6: bikes_by_type (Proper Partition Design)

**Query Pattern**: Find bikes by type and status for fleet management

### Table Definition

```cql
CREATE TABLE IF NOT EXISTS bikeshare.bikes_by_type (
    bike_type TEXT,
    status TEXT,
    bike_id UUID,
    model TEXT,
    battery_level INT,
    current_station_id UUID,
    last_maintenance_date DATE,
    total_distance_km DECIMAL,
    PRIMARY KEY ((bike_type, status), last_maintenance_date, bike_id)
) WITH CLUSTERING ORDER BY (last_maintenance_date DESC, bike_id ASC)
AND comment = 'Q6: Bikes grouped by type and status for fleet management';

-- Optional: SAI index for additional filtering within partition
CREATE INDEX IF NOT EXISTS bikes_battery_level_sai_idx 
ON bikeshare.bikes_by_type(battery_level) 
USING 'sai';
```

**Design Rationale:**
- Compound Partition Key: `(bike_type, status)` for common query patterns
- Clustering: `last_maintenance_date DESC` for natural ordering
- Single-partition reads (fast!)
- SAI within partition for battery filtering
- Denormalization: Accepts write cost for read performance

### Sample Data

```cql
-- Standard bikes - available
INSERT INTO bikeshare.bikes_by_type (bike_type, status, bike_id, model, battery_level,
    current_station_id, last_maintenance_date, total_distance_km)
VALUES (
    'standard', 'available',
    aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa, 'Urban Cruiser X1', null,
    11111111-1111-1111-1111-111111111111, '2025-10-25', 2547.8
);

INSERT INTO bikeshare.bikes_by_type (bike_type, status, bike_id, model, battery_level,
    current_station_id, last_maintenance_date, total_distance_km)
VALUES (
    'standard', 'available',
    cccccccc-cccc-cccc-cccc-cccccccccccc, 'Urban Cruiser X2', null,
    11111111-1111-1111-1111-111111111111, '2025-10-20', 3891.2
);

-- Electric bikes - available
INSERT INTO bikeshare.bikes_by_type (bike_type, status, bike_id, model, battery_level,
    current_station_id, last_maintenance_date, total_distance_km)
VALUES (
    'electric', 'available',
    bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb, 'E-Bike Pro 3000', 95,
    11111111-1111-1111-1111-111111111111, '2025-10-24', 1234.5
);

INSERT INTO bikeshare.bikes_by_type (bike_type, status, bike_id, model, battery_level,
    current_station_id, last_maintenance_date, total_distance_km)
VALUES (
    'electric', 'available',
    dddddddd-dddd-dddd-dddd-dddddddddddd, 'E-Bike Pro 3000', 78,
    22222222-2222-2222-2222-222222222222, '2025-10-22', 876.3
);

INSERT INTO bikeshare.bikes_by_type (bike_type, status, bike_id, model, battery_level,
    current_station_id, last_maintenance_date, total_distance_km)
VALUES (
    'electric', 'available',
    eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee, 'E-Bike Pro 3000', 42,
    33333333-3333-3333-3333-333333333333, '2025-10-15', 1567.9
);

-- Electric bikes - charging
INSERT INTO bikeshare.bikes_by_type (bike_type, status, bike_id, model, battery_level,
    current_station_id, last_maintenance_date, total_distance_km)
VALUES (
    'electric', 'charging',
    12121212-1212-1212-1212-121212121212, 'E-Bike Pro 3000', 15,
    11111111-1111-1111-1111-111111111111, '2025-10-18', 2134.7
);

-- Standard bikes - in maintenance
INSERT INTO bikeshare.bikes_by_type (bike_type, status, bike_id, model, battery_level,
    current_station_id, last_maintenance_date, total_distance_km)
VALUES (
    'standard', 'in_maintenance',
    ffffffff-ffff-ffff-ffff-ffffffffffff, 'Mountain Beast', null,
    22222222-2222-2222-2222-222222222222, '2025-10-10', 4321.7
);
```

### Example Queries (All single-partition reads!)

```cql
-- Get all available e-bikes
SELECT bike_id, model, battery_level, last_maintenance_date, current_station_id
FROM bikeshare.bikes_by_type
WHERE bike_type = 'electric' AND status = 'available';
-- Expected: 3 bikes ordered by maintenance date DESC
-- Performance: SINGLE PARTITION - FAST!

-- Get available standard bikes
SELECT bike_id, model, last_maintenance_date, total_distance_km
FROM bikeshare.bikes_by_type
WHERE bike_type = 'standard' AND status = 'available';
-- Expected: 2 bikes

-- Get bikes currently charging
SELECT bike_id, model, battery_level, last_maintenance_date
FROM bikeshare.bikes_by_type
WHERE bike_type = 'electric' AND status = 'charging';
-- Expected: 1 bike

-- Find available e-bikes with low battery (SAI within partition)
SELECT bike_id, model, battery_level, current_station_id
FROM bikeshare.bikes_by_type
WHERE bike_type = 'electric' 
  AND status = 'available'
  AND battery_level < 50;
-- Expected: 1 bike (battery = 42)
-- Performance: Single partition + SAI (GOOD pattern!)

-- Recently maintained available e-bikes
SELECT bike_id, model, battery_level, last_maintenance_date
FROM bikeshare.bikes_by_type
WHERE bike_type = 'electric' 
  AND status = 'available'
  AND last_maintenance_date >= '2025-10-20';
-- Expected: 2 bikes (Oct 24, Oct 22)
```

---

## Q7: bike_rental_counts

**Query Pattern**: Track rental counts using COUNTER

### Table Definition

```cql
CREATE TABLE IF NOT EXISTS bikeshare.bike_rental_counts (
    bike_id UUID,
    model TEXT,
    bike_type TEXT,
    total_rentals COUNTER,
    PRIMARY KEY (bike_id, model, bike_type)
) WITH comment = 'Q7: Track rental counts per bike using COUNTER';
```

**Design Rationale:**
- ALL non-counter columns MUST be in PRIMARY KEY
- Counter for atomic increments
- No INSERT allowed - only UPDATE

### Sample Operations

```cql
-- Increment counters (run multiple times)
UPDATE bikeshare.bike_rental_counts
SET total_rentals = total_rentals + 1
WHERE bike_id = aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa
  AND model = 'Urban Cruiser X1'
  AND bike_type = 'standard';

UPDATE bikeshare.bike_rental_counts
SET total_rentals = total_rentals + 1
WHERE bike_id = aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa
  AND model = 'Urban Cruiser X1'
  AND bike_type = 'standard';

UPDATE bikeshare.bike_rental_counts
SET total_rentals = total_rentals + 1
WHERE bike_id = bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb
  AND model = 'E-Bike Pro 3000'
  AND bike_type = 'electric';
```

### Example Queries

```cql
-- Get rental count for specific bike
SELECT bike_id, model, bike_type, total_rentals
FROM bikeshare.bike_rental_counts
WHERE bike_id = aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa
  AND model = 'Urban Cruiser X1'
  AND bike_type = 'standard';
-- Expected: total_rentals = 2
```

---

## Features Summary

| Feature | Query | Table |
|---------|-------|-------|
| Simple Partition Key | Q1, Q3 | bikes_by_station, stations |
| Compound Partition Key | Q2, Q6 | rentals_by_user_month, bikes_by_type |
| Clustering Columns | Q1, Q2, Q4, Q5, Q6 | Most tables |
| Time Bucketing | Q2 | rentals_by_user_month |
| Query Optimization Partition | Q6 | bikes_by_type (type+status) |
| SAI within Partition | Q1, Q6 | status, battery_level |
| UDT | Q5 | maintenance_by_bike (parts_info) |
| Collections (LIST) | Q5 | maintenance_by_bike |
| COUNTER | Q7 | bike_rental_counts |
| Denormalization | Q2, Q4, Q6 | Multiple tables |

---

## Key Teaching Points

### SAI Best Practices
- ✅ **Q1**: Single partition + SAI on status (GOOD)
- ✅ **Q6**: Single partition + SAI on battery_level (GOOD)
- ❌ **Anti-pattern**: SAI without partition key (avoid in production)

### Partition Key Design
- **Q1**: By station (location-based queries)
- **Q2**: By (user, month) - prevents unbounded growth
- **Q6**: By (type, status) - optimizes common queries

### When to Use Compound Partition Keys
1. **Time Bucketing** (Q2): Prevent unbounded partitions
2. **Query Optimization** (Q6): Match common query patterns
3. **Rule**: Include attributes you ALWAYS filter by

### Design Trade-offs
- **Denormalization**: Duplicate data for read performance
- **Write cost**: Accept higher writes for faster reads
- **Partition size**: Keep bounded with bucketing
- **One query = one table**: Cassandra principle

---

## Common Mistakes to Avoid

❌ Don't use ALLOW FILTERING in production  
❌ Don't forget keyspace prefix in table names  
❌ Don't use SAI without partition key for high-frequency queries  
❌ Don't create unbounded partitions (use bucketing)  

✅ Use SAI within partitions for flexible filtering  
✅ Design proper partition keys matching query patterns  
✅ Use compound partition keys for bucketing  
✅ Denormalize data for read performance  
✅ All queries should be single-partition reads when possible