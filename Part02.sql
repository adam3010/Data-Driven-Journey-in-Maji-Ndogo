-- ----- Cleaning our data ------ --

-- SELECT CONCAT(LOWER(Replace(employee_name,' ','.')),'@ndogowater.gov') AS email
-- FROM employee;

-- UPDATE employee
-- SET email = CONCAT(LOWER(Replace(employee_name,' ','.')),'@ndogowater.gov') 

-- update employee
-- SET phone_number = trim(phone_number)

-- ------ Honoring our workers ------ --

-- get the best three empolyees
-- select town_name , count(assigned_employee_id)
-- from employee
-- group by town_name

-- select assigned_employee_id , count(location_id) as number_of_locations
-- from visits
-- group by assigned_employee_id
-- order by number_of_locations DES
-- limit 3

-- ----- Analyzing Locations ----- --

-- a query that counts the number of records per town

select count(location_id) as records_per_town , town_name
from location
group by town_name
order by records_per_town DESC;

-- Count the records per province.

select count(location_id) as records_per_province , province_name
from location
group by province_name
order by records_per_province DESC;

-- 1. Create a result set showing:
-- • province_name
-- • town_name
-- • An aggregated count of records for each town (consider naming this records_per_town).
-- • Ensure your data is grouped by both province_name and town_name.
-- 2. Order your results primarily by province_name. Within each province, further sort the towns by their record counts in descending order

select province_name , town_name , count(location_id) AS records_per_town
from location
group by province_name , town_name
order by province_name ASC , records_per_town DESC;

--  look at the number of records for each location type
select location_type , count(location_id) as records_per_location_type
from location
group by  location_type;

SELECT 23740 / (15910 + 23740) * 100;

-- what are some of the insights we gained from the location table?
-- 1. Our entire country was properly canvassed, and our dataset represents the situation on the ground.
-- 2. 60% of our water sources are in rural communities across Maji Ndogo. We need to keep this in mind when we make decisions.

-- ----- Diving into the sources ----- --

-- These are the questions that I am curious about.
-- 1. How many people did we survey in total?
select sum(number_of_people_served) as number_of_survaies from water_source;

-- 2. How many wells, taps and rivers are there?
select type_of_water_source , count(source_id) as source_count
from water_source
group by type_of_water_source;

-- 3. How many people share particular types of water sources on average?
select type_of_water_source , round(avg(number_of_people_served)) as avg_people_per_source
from water_source
group by type_of_water_source;

-- 4. How many people are getting water from each type of source?
select type_of_water_source , sum(number_of_people_served)  as total_people_per_source 
from water_source
group by type_of_water_source
order by total_people_per_source DESC;

select type_of_water_source , round((sum(number_of_people_served) / 27628140) * 100)  as percentage_people_per_source 
from water_source
group by type_of_water_source
order by percentage_people_per_source DESC;

-- 43% of our people are using shared taps in their communities, and on average, we saw earlier, that 2000 people share one shared_tap.
-- By adding tap_in_home and tap_in_home_broken together, we see that 31% of people have water infrastructure installed in their homes, but 45%
-- (14/31) of these taps are not working! This isn't the tap itself that is broken, but rather the infrastructure like treatment plants, reservoirs, pipes, and
-- pumps that serve these homes that are broken.
-- 18% of people are using wells. But only 4916 out of 17383 are clean = 28% (from part01).


-- ----- Start a solution ----- --

-- use a window function on the total people served column, converting it into a rank
select type_of_water_source , sum(number_of_people_served) as total_served_people,
		RANK() over(order by sum(number_of_people_served ) DESC) AS rank_by_polution
from water_source
group by type_of_water_source
order by rank_by_polution;

-- So create a query to do this, and keep these requirements in mind:
-- 1. The sources within each type should be assigned a rank.
-- 2. Limit the results to only improvable sources.
-- 3. Think about how to partition, filter and order the results set.
-- 4. Order the results to see the top of the list

select source_id, type_of_water_source, sum(number_of_people_served) as total_served_people,
    rank() over(partition by type_of_water_source order by sum(number_of_people_served) ) AS priority_rank
from water_source
where type_of_water_source != 'tap_in_home'
group by source_id , type_of_water_source 
order by total_served_people DESC;

-- ----- Start a solution ----- --

-- Ok, these are some of the things I think are worth looking at:
-- 1. How long did the survey take?

SELECT datediff( MAX(time_of_record) , MIN(time_of_record) )AS min_order_date
FROM visits;
-- 2. What is the average total queue time for water?
select avg(nullif(time_in_queue , 0))
from visits;

-- 3. What is the average queue time on different days?
select dayname(time_of_record) as Day_Name , round(avg(nullif(time_in_queue , 0)),0) 
from visits
group by Day_Name;

-- 4. How can we communicate this information efficiently?

select TIME_FORMAT(TIME(time_of_record), '%H:00') as hour_in_day ,round(avg(nullif(time_in_queue , 0)),0) as avg_time
from visits
group by hour_in_day
order by hour_in_day; 

-- -- creating pivot table for comapre hours in days

SELECT
TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,
-- Sunday
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Sunday' THEN time_in_queue
ELSE NULL
END
),0) AS Sunday,
-- Monday
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Monday' THEN time_in_queue
ELSE NULL
END
),0) AS Monday,

-- Tuesday
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Tuesday' THEN time_in_queue
ELSE NULL
END
),0) AS Tuesday,
-- Wednesday
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Wednesday' THEN time_in_queue
ELSE NULL
END
),0) AS Wednesday,
-- Thursday
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Thursday' THEN time_in_queue
ELSE NULL
END
),0) AS Thursday,
-- Friday
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Friday' THEN time_in_queue
ELSE NULL
END
),0) AS Friday,
-- 
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Saturday' THEN time_in_queue
ELSE NULL
END
),0) AS Saturday
FROM
visits
WHERE
time_in_queue != 0 -- this excludes other sources with 0 queue times
GROUP BY
hour_of_day
ORDER BY
hour_of_day;


-- ----- SUmmary ------ --
-- Insights
-- 1. Most water sources are rural.
-- 2. 43% of our people are using shared taps. 2000 people often share one tap.
-- 3. 31% of our population has water infrastructure in their homes, but within that group, 45% face non-functional systems due to issues with pipes,
-- pumps, and reservoirs.
-- 4. 18% of our people are using wells of which, but within that, only 28% are clean..
-- 5. Our citizens often face long wait times for water, averaging more than 120 minutes.
-- 6. In terms of queues:
-- - Queues are very long on Saturdays.
-- - Queues are longer in the mornings and evenings.
-- - Wednesdays and Sundays have the shortest queues.



 
