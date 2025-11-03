# Apache Cassandra 5 Data Modeling Training Exercise

## Use Case: Smart City Bike Sharing System

You are designing a data model for **BikeShare Pro**, a smart city bike-sharing service that operates in multiple cities. The system tracks bikes, stations, rentals, user activity, and maintenance records.

---

## Domain Model Overview

Before starting, understand the entities in our system:

### Bikes
- **bike_id** (UUID): Unique identifier for each bike
- **model** (TEXT): Bike model name (e.g., "Urban Cruiser X1", "E-Bike Pro 3000")
- **bike_type** (TEXT): Type of bike - "standard" or "electric"
- **battery_level** (INT): Battery percentage (0-100) for electric bikes, null for standard bikes
- **status** (TEXT): Current status - "available", "in_use", "in_maintenance", "charging"
- **last_maintenance_date** (DATE): When the bike was last serviced
- **current_station_id** (UUID): Current station where bike is located (for Q6)
- **total_distance_km** (DECIMAL): Total kilometers traveled by bike (for Q6)

### Stations
- **station_id** (UUID): Unique identifier for each station
- **station_name** (TEXT): Station name (e.g., "Downtown Hub", "University Campus")
- **city** (TEXT): City name (e.g., "San Francisco", "Oakland")
- **latitude, longitude** (DECIMAL): GPS coordinates
- **total_docks** (INT): Total number of bike docks
- **available_bikes** (INT): Current count of bikes at station
- **postal_code** (TEXT): Station postal code

### Rentals
- **rental_id** (UUID): Unique identifier for each rental
- **user_id** (UUID): User who rented the bike
- **bike_id** (UUID): Bike that was rented
- **start_time** (TIMESTAMP): When rental started
- **rental_month** (TEXT): Format "YYYY-MM" (e.g., "2025-10") for time bucketing
- **start_station_name, end_station_name** (TEXT): Station names
- **duration_minutes** (INT): How long the rental lasted
- **cost** (DECIMAL): Rental cost in dollars

### Maintenance Records
- **maintenance_id** (UUID): Unique identifier for maintenance event
- **bike_id** (UUID): Bike that was serviced
- **maintenance_date** (TIMESTAMP): When maintenance occurred
- **technician_name** (TEXT): Technician who performed service
- **issue_description** (TEXT): Description of the problem/service
- **parts_replaced** (LIST<FROZEN<parts_info>>): List of parts replaced (use UDT)
- **total_cost** (DECIMAL): Total cost of maintenance

### Parts Info (User Defined Type)
```cql
CREATE TYPE bikeshare.parts_info (
    part_name TEXT,
    part_cost DECIMAL,
    quantity INT
);
```

---

## Application Requirements

**Q1: Find Available Bikes at a Station**  
Find all available bikes at a specific station, ordered by last maintenance date

**Example Use Case**: A mobile app user opens the app at "Downtown Hub" and wants to see all bikes available for rent, with recently maintained bikes shown first.

**Q2: User Rental History by Month**  
Get rental history for a user for a specific month, ordered by most recent first

**Example Use Case**: A user wants to view their October 2025 rental history to check their monthly usage and costs.

**Q3: Station Information Lookup**  
Get detailed information about a specific station

**Example Use Case**: System needs to quickly look up station details by station_id to display location, capacity, and current bike availability.

**Q4: Search Stations by City**  
Find all stations in a specific city

**Example Use Case**: An administrator wants to see all stations in "San Francisco" for city-wide management and reporting.

**Q5: Maintenance History per Bike**  
Get maintenance history for a specific bike, ordered by date

**Example Use Case**: A technician needs to view complete maintenance history for a specific bike to diagnose recurring issues.

**Q6: Find Bikes by Type and Status**  
Find bikes by type and status for fleet management

**Example Use Case**: Fleet manager wants to see all available electric bikes, or all standard bikes currently in maintenance.

**Q7: Track Bike Rental Counts**  
Track how many times each bike has been rented

**Example Use Case**: System needs to increment a counter each time a bike is rented to track usage for maintenance scheduling and analytics.

---

## Student Exercise (50 minutes)

For each query pattern above, you need to:
1. **Create the appropriate table(s)** with correct PRIMARY KEY design
2. **Insert sample data** to test your queries
3. **Write the CQL queries** to answer the application requirements

### Important Cassandra Concepts to Apply

**Partition Keys**: Determines which node stores the data. Always required in WHERE clause.
- Use the column you're querying by most frequently
- Keep partitions bounded (use compound keys or time bucketing if needed)

**Clustering Columns**: Determines sort order within a partition
- Use for ordering results
- Can be used in WHERE clause with comparison operators (>=, <=, etc.)

**Compound Partition Keys**: Multiple columns in partition key: `((col1, col2))`
- Use for time bucketing (e.g., user_id + month)
- Use to optimize common query patterns (e.g., bike_type + status)

**SAI Indexes**: SAI indexes can efficiently filter on non-primary-key columns, **but require a partition key for efficient queries**. Do not confuse SAI with the CQL `ALLOW FILTERING` option. For best performance, always query with the partition key **and** SAI filter within that partition. Queries using SAI without a partition key are not recommended in production.

**UDTs (User Defined Types)**: Structured data types for complex fields
- Use FROZEN when storing in collections
- Good for grouping related attributes (e.g., parts information)

**COUNTER Tables**: Special tables for incrementing values
- ALL non-counter columns must be in PRIMARY KEY
- Cannot INSERT, only UPDATE
- Use for tracking counts that change frequently

---

### Hints

**Q1**: Partition by station_id, cluster by maintenance date DESC, use SAI for status  

**Q2**: Compound partition key (user_id, month) for time bucketing  

**Q3**: Simple primary key lookup  

**Q4**: Partition by city  

**Q5**: Partition by bike_id, use UDT for parts  

**Q6**: Compound partition key (bike_type, status) for fleet queries  

**Q7**: COUNTER table - all non-counter columns in PRIMARY KEY

---

## Getting Started

1. **Use your allocated student keyspace**: Each of you has been assigned a pre-existing keyspace (e.g., `student1`, `student2`, etc.). Use this keyspace for all your tables. For example:
```cql
CREATE TABLE student1.bikes_by_station (
    station_id UUID,
    ...
);
```

2. **For Q5, create the UDT in your keyspace**:
```cql
CREATE TYPE IF NOT EXISTS student1.parts_info (
    part_name TEXT,
    part_cost DECIMAL,
    quantity INT
);
```

3. **Use sample UUIDs** for testing:
- Stations: `11111111-1111-1111-1111-111111111111`, `22222222-2222-2222-2222-222222222222`
- Bikes: `aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa`, `bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb`
- Users: `99999999-9999-9999-9999-999999999999`

4. **Always prefix table names with your student keyspace**: `student1.table_name` (or your assigned keyspace name)

---

## What Success Looks Like

By the end of this exercise, you should have:
- ✅ 7 different table designs, each optimized for its query pattern
- ✅ Working INSERT statements with realistic sample data
- ✅ Working SELECT queries that efficiently answer each application requirement
- ✅ Understanding of when to use: simple vs compound partition keys, clustering columns, SAI indexes, UDTs, and COUNTERs
- ✅ All queries reading from single partitions (the Cassandra way!)

---

## Common Beginner Mistakes to Avoid

❌ Forgetting to include partition key in WHERE clause  
❌ Trying to ORDER BY a non-clustering column  
❌ Using ALLOW FILTERING (it's a red flag in production!)  
❌ Creating unbounded partitions (use time bucketing!)  
❌ Forgetting FROZEN keyword with UDTs in collections  
❌ Trying to INSERT into COUNTER tables (use UPDATE only!)  

✅ Design tables around your queries (query-first approach)  
✅ Keep partition sizes reasonable (use bucketing for time-series data)  
✅ Use SAI within partitions for flexible filtering  
✅ Test your queries with sample data to verify they work!  

---

Good luck! Remember: In Cassandra, we design tables for specific queries, not for normalized data models. One query pattern = one table is perfectly normal, but also dont be afraid to use SAI indexing.