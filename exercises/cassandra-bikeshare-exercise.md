# Apache Cassandra 5 Data Modeling Training Exercise

## Use Case: Smart City Bike Sharing System

You are designing a data model for "BikeShare Pro", a smart city bike-sharing service that operates in multiple cities. The system tracks bikes, stations, rentals, user activity, and maintenance records.

---

## Application Requirements

**Q1: Find Available Bikes at a Station**  
Find all available bikes at a specific station, ordered by last maintenance date

**Q2: User Rental History by Month**  
Get rental history for a user for a specific month, ordered by most recent first

**Q3: Station Information Lookup**  
Get detailed information about a specific station

**Q4: Search Stations by City**  
Find all stations in a specific city

**Q5: Maintenance History per Bike**  
Get maintenance history for a specific bike, ordered by date

**Q6: Find Bikes by Type and Status**  
Find bikes by type and status for fleet management

**Q7: Track Bike Rental Counts**  
Track how many times each bike has been rented

---

## Student Exercise (50 minutes)

### Hints

**Q1**: Partition by station_id, cluster by maintenance date DESC, use SAI for status  
**Q2**: Compound partition key (user_id, month) for time bucketing  
**Q3**: Simple primary key lookup  
**Q4**: Partition by city  
**Q5**: Partition by bike_id, use UDT for parts  
**Q6**: Compound partition key (bike_type, status) for fleet queries  
**Q7**: COUNTER table - all non-counter columns in PRIMARY KEY

---
