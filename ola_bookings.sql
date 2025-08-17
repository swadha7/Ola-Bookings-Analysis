create database ola;
use ola;

create view successful_bookings as
select * from bookings 
where booking_status = 'success';

create view avg_ride_distance_for_each_vehicle_type as
select vehicle_type, 
round(avg(ride_distance),2) as avg_ride_distance
from bookings
group by vehicle_type;

create view cancelled_rides_by_customers as
select count(*)
from bookings
where booking_status = 'Canceled by Customer';

create view top_5_customers_by_total_rides as
select customer_id, 
count(booking_id) as number_of_rides
from bookings
group by customer_id
order by number_of_rides desc
limit 5;

create view rides_cancelled_by_driver_for_pac_issues as
select count(canceled_rides_by_driver) as number_of_rides_cancelled
from bookings
where canceled_rides_by_driver = 'Personal & Car related issue'; 

create view max_min_driver_ratings_for_Prime_Sedan as
select max(driver_ratings) as maximum_driver_rating,
min(driver_ratings) as minimum_driver_rating
from bookings
where vehicle_type = 'Prime Sedan';

create view rides_with_upi_payment as
select *
from bookings
where payment_method = 'UPI';

create view average_customer_rating_per_vehicle_type as
select vehicle_type, 
round(avg(customer_rating),2) as avg_customer_rating
from bookings
group by vehicle_type;

create view total_booking_value_successful_rides as
select sum(booking_value) as total_booking_value
from bookings
where booking_status = 'success';

create view incomplete_rides_with_reason as
select booking_id, incomplete_rides_reason 
from bookings 
where incomplete_rides = 'Yes';

-- 1. Retrieve all successful bookings:
select * from successful_bookings;

-- 2. Find the average ride distance for each vehicle type:
select * from avg_ride_distance_for_each_vehicle_type;

-- 3. Get the total number of cancelled rides by customers:
select * from cancelled_rides_by_customers;

-- 4. List the top 5 customers who booked the highest number of rides:
select * from top_5_customers_by_total_rides;

-- 5. Get the number of rides cancelled by drivers due to personal and car-related issues:
select * from rides_cancelled_by_driver_for_pac_issues;

-- 6. Find the maximum and minimum driver ratings for Prime Sedan bookings:
select * from max_min_driver_ratings_for_Prime_Sedan;

-- 7. Retrieve all rides where payment was made using UPI:
select * from rides_with_upi_payment;

-- 8. Find the average customer rating per vehicle type:
select * from average_customer_rating_per_vehicle_type;

-- 9. Calculate the total booking value of rides completed successfully:
select * from total_booking_value_successful_rides;

-- 10. List all incomplete rides along with the reason:
select * from incomplete_rides_with_reason;

-- 11. Rank pickup→drop pairs by total booking value; show % of total revenue and cumulative %.
WITH revenue AS (
    SELECT 
        Pickup_Location,
        Drop_Location,
        SUM(Booking_Value) AS total_revenue
    FROM ola.bookings
    WHERE Booking_Status = 'Success'
    GROUP BY Pickup_Location, Drop_Location
),
ranked AS (
    SELECT 
        Pickup_Location,
        Drop_Location,
        total_revenue,
        ROUND(100.0 * total_revenue / SUM(total_revenue) OVER(), 2) AS pct_of_total,
        ROUND(100.0 * SUM(total_revenue) OVER(ORDER BY total_revenue DESC) / SUM(total_revenue) OVER(), 2) AS cum_pct
    FROM revenue
)
SELECT * 
FROM ranked
ORDER BY total_revenue DESC;

-- 12. Find cancellation rate by vehicle type, split by driver vs customer cancellations; compare to overall rate.

WITH overall AS (
  SELECT
    COUNT(*) AS overall_total,
    SUM(CASE WHEN Booking_Status IN ('Canceled by Driver','Canceled by Customer') THEN 1 ELSE 0 END) AS overall_cancels
  FROM ola.bookings
),
type_totals AS (
  SELECT
    Vehicle_Type,
    COUNT(*) AS total_rides,
    SUM(CASE WHEN Booking_Status IN ('Canceled by Driver','Canceled by Customer') THEN 1 ELSE 0 END) AS total_cancels
  FROM ola.bookings
  GROUP BY Vehicle_Type
),
breakdown AS (
  SELECT
    Vehicle_Type,
    Booking_Status,
    COUNT(*) AS cancels
  FROM ola.bookings
  WHERE Booking_Status IN ('Canceled by Driver','Canceled by Customer')
  GROUP BY Vehicle_Type, Booking_Status
)
SELECT
  b.Vehicle_Type,
  b.Booking_Status,
  b.cancels,
  t.total_rides,
  ROUND(100.0 * b.cancels / t.total_rides, 2)         AS pct_within_type,    -- % of this status within that vehicle type
  ROUND(100.0 * t.total_cancels / t.total_rides, 2)   AS type_cancel_rate,   -- overall cancel rate for that vehicle type
  ROUND(100.0 * o.overall_cancels / o.overall_total,2) AS overall_cancel_rate, -- overall cancel rate across all types
  ROUND( (100.0 * t.total_cancels / t.total_rides)
       - (100.0 * o.overall_cancels / o.overall_total), 2) AS diff_vs_overall
FROM breakdown b
JOIN type_totals t ON b.Vehicle_Type = t.Vehicle_Type
CROSS JOIN overall o
ORDER BY t.total_cancels DESC, b.cancels DESC;

-- 12. Find cancellation rate by vehicle type, split by driver vs customer cancellations; compare to overall rate.
WITH overall AS (
  SELECT
    COUNT(*) AS overall_total,
    SUM(CASE WHEN Booking_Status IN ('Canceled by Driver','Canceled by Customer') THEN 1 ELSE 0 END) AS overall_cancels
  FROM ola.bookings
),
type_totals AS (
  SELECT
    Vehicle_Type,
    COUNT(*) AS total_rides,
    SUM(CASE WHEN Booking_Status IN ('Canceled by Driver','Canceled by Customer') THEN 1 ELSE 0 END) AS total_cancels
  FROM ola.bookings
  GROUP BY Vehicle_Type
),
breakdown AS (
  SELECT
    Vehicle_Type,
    Booking_Status,
    COUNT(*) AS cancels
  FROM ola.bookings
  WHERE Booking_Status IN ('Canceled by Driver','Canceled by Customer')
  GROUP BY Vehicle_Type, Booking_Status
)
SELECT
  b.Vehicle_Type,
  b.Booking_Status,
  b.cancels,
  t.total_rides,
  ROUND(100.0 * b.cancels / t.total_rides, 2)         AS pct_within_type,    -- % of this status within that vehicle type
  ROUND(100.0 * t.total_cancels / t.total_rides, 2)   AS type_cancel_rate,   -- overall cancel rate for that vehicle type
  ROUND(100.0 * o.overall_cancels / o.overall_total,2) AS overall_cancel_rate, -- overall cancel rate across all types
  ROUND( (100.0 * t.total_cancels / t.total_rides)
       - (100.0 * o.overall_cancels / o.overall_total), 2) AS diff_vs_overall
FROM breakdown b
JOIN type_totals t ON b.Vehicle_Type = t.Vehicle_Type
CROSS JOIN overall o
ORDER BY t.total_cancels DESC, b.cancels DESC;

