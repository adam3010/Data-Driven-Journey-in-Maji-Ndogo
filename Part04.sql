-- We still have a bit of analysis to wrap up, and then we need to create a table to track our progress.

-- Let's summarise the data we need, and where to find it:
-- • All of the information about the location of a water source is in the location table, specifically the town and province of that water source.
-- • water_source has the type of source and the number of people served by each source.
-- • visits has queue information, and connects source_id to location_id. There were multiple visits to sites, so we need to be careful to
-- include duplicate data (visit_count > 1 ).
-- • well_pollution has information about the quality of water from only wells, so we need to keep that in mind when we join this table.


-- ------jOINING PIECES TOGETHER------- --
CREATE VIEW combined_analysis_table as(  -- This view assembles data from different tables into one to simplify analysis
select L.province_name ,
		L.town_name ,
        WS.type_of_water_source as source_type,
        L.location_type, 
        WS.number_of_people_served as people_served, 
        V.time_in_queue , 
        WP.results
from location as L
JOIN visits as V
ON L.location_id = V.location_id
JOIN water_source as WS
ON V.source_id = WS.source_id
LEFT JOIN well_pollution as WP
ON WP.source_id = V.source_id
 WHERE V.visit_count = 1);
SELECT * FROM combined_analysis_table;

-- ------THE LAST ANALYSIS-------- --
--  we want to break down our data into provinces or towns and source types

WITH province_totals AS (-- This CTE calculates the population of each province
SELECT
province_name,
SUM(people_served) AS total_ppl_serv
FROM
combined_analysis_table
GROUP BY
province_name
)
SELECT
ct.province_name,
-- These case statements create columns for each type of source.
-- The results are aggregated and percentages are calculated
ROUND((SUM(CASE WHEN source_type = 'river'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN source_type = 'shared_tap'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN source_type = 'well'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
JOIN
province_totals pt ON ct.province_name = pt.province_name
GROUP BY
ct.province_name
ORDER BY
ct.province_name;

-- Run the query and see if you can spot any of the following patterns:
-- • Look at the river column, Sokoto has the largest population of people drinking river water. We should send our drilling equipment to Sokoto
-- first, so people can drink safe filtered water from a well.
-- • The majority of water from Amanzi comes from taps, but half of these home taps don't work because the infrastructure is broken. We need to
-- send out engineering teams to look at the infrastructure in Amanzi first. Fixing a large pump, treatment plant or reservoir means that
-- thousands of people will have running water. This means they will also not have to queue for water, so we improve two things at once.


CREATE TEMPORARY TABLE town_aggregated_water_access
WITH town_totals AS( -- This CTE calculates the population of each town
-- Since there are two Harare towns, we have to group by province_name and town_name
SELECT province_name, town_name, SUM(people_served) AS total_ppl_serv
FROM combined_analysis_table
GROUP BY province_name,town_name
)
SELECT
ct.province_name,
ct.town_name,
ROUND((SUM(CASE WHEN source_type = 'river'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN source_type = 'shared_tap'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN source_type = 'well'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
JOIN -- Since the town names are not unique, we have to join on a composite key
town_totals tt ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name
GROUP BY -- We group by province first, then by town.
ct.province_name,
ct.town_name
ORDER BY
ct.town_name;

select * from town_aggregated_water_access;

select province_name , town_name,
		ROUND(tap_in_home_broken / (tap_in_home_broken + tap_in_home) *100 , 0) AS Pct_broken_taps
from town_aggregated_water_access;

-- -----Summary report------ --

-- Insights
-- Ok, so let's sum up the data we have.
-- A couple of weeks ago we found some interesting insights:
-- 1. Most water sources are rural in Maji Ndogo.
-- 2. 43% of our people are using shared taps. 2000 people often share one tap.
-- 3. 31% of our population has water infrastructure in their homes, but within that group,
-- 4. 45% face non-functional systems due to issues with pipes, pumps, and reservoirs. Towns like Amina, the rural parts of Amanzi, and a couple
-- of towns across Akatsi and Hawassa have broken infrastructure.
-- 5. 18% of our people are using wells of which, but within that, only 28% are clean. These are mostly in Hawassa, Kilimani and Akatsi.
-- 6. Our citizens often face long wait times for water, averaging more than 120 minutes:
-- • Queues are very long on Saturdays.
-- • Queues are longer in the mornings and evenings.
-- • Wednesdays and Sundays have the shortest queues.



-- ----------- Plan the action ------------ --
-- create progress table 
CREATE TABLE Project_progress (
Project_id SERIAL PRIMARY KEY,

source_id VARCHAR(20) NOT NULL REFERENCES water_source(source_id) ON DELETE CASCADE ON UPDATE CASCADE,

Address VARCHAR(50), -- Street address
Town VARCHAR(30),
Province VARCHAR(30),
Source_type VARCHAR(50),
Improvement VARCHAR(50), -- What the engineers should do at that place
Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In progress', 'Complete')),

Date_of_completion DATE, -- Engineers will add this the day the source has been upgraded.
Comments TEXT -- Engineers can leave comments. We use a TEXT type that has no limit on char length
);


INSERT INTO project_progress (Address , Town , Province , source_id, Source_type, Improvement)
SELECT
location.address,
location.town_name,
location.province_name,
water_source.source_id,
water_source.type_of_water_source,
#well_pollution.results,
CASE 
WHEN well_pollution.results = 'Contaminated: Chemical'  THEN 'Install UV filter'
WHEN well_pollution.results in ('Contaminated: Chemical','Contaminated: Biological') THEN 'Install UV filter and Install RO filter'
WHEN water_source.type_of_water_source ='river' THEN 'Drill well'
WHEN water_source.type_of_water_source = 'shared_tap' THEN CONCAT('Install ', FLOOR(visits.time_in_queue / 30) ,' taps')
WHEN water_source.type_of_water_source = 'tap_in_home_broken' THEN 'Diagonse infreastructure'
ELSE NULL
END AS Improvment
FROM
water_source
LEFT JOIN
well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
visits ON water_source.source_id = visits.source_id
INNER JOIN
location ON location.location_id = visits.location_id
where visits.visit_count = 1
AND (water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30)
OR well_pollution.results != 'Clean'
OR water_source.type_of_water_source in ('river','tap_in_home_broken');


select * from project_progress;

