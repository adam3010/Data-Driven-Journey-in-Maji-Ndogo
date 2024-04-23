-- ------- Integrating the Auditor's report ----------- --
DROP TABLE IF exists auditor_report;

CREATE TABLE `auditor_report` (
`location_id` VARCHAR(32),
`type_of_water_source` VARCHAR(64),
`true_water_source_score` int DEFAULT NULL,
`statements` VARCHAR(255)
);

-- We need to tackle a couple of questions here.
-- 1. Is there a difference in the scores?
SELECT v.location_id as visit_location ,v.record_id, ar.true_water_source_score as auditor_score,
			wq.subjective_quality_score as surveyor_score 
FROM auditor_report AS ar
Join visits as v
on ar.location_id = v.location_id
Join water_quality as wq
ON v.record_id = wq.record_id
WHERE ar.true_water_source_score = wq.subjective_quality_score
AND v.visit_count = 1;
-- I think that is an excellent result. 1518/1620 = 94% of the records the auditor checked were correct!!

-- It looks like some of our surveyors are making a lot of "mistakes" while many of the other surveyors are only making a few. I don't like where this is
-- going!

-- ------------ Linking records AND Gathering some evidence ------------- --
with Incorrect_records as(
SELECT v.location_id as visit_location ,v.record_id, v.assigned_employee_id, E.employee_name,
			ar.true_water_source_score as auditor_score,
			wq.subjective_quality_score as surveyor_score 
FROM auditor_report AS ar
Join visits as v
	on ar.location_id = v.location_id
Join water_quality as wq
	ON v.record_id = wq.record_id
JOIN employee as E
	on v.assigned_employee_id = E.assigned_employee_id
WHERE ar.true_water_source_score != wq.subjective_quality_score
	AND v.visit_count = 1),
error_count AS( 
	select distinct(employee_name) as employee_name, count(assigned_employee_id) as number_of_mistakes
	from Incorrect_records
	group by employee_name
	order by number_of_mistakes ASC),
avg_error_count_per_empl AS(
	select AVG(number_of_mistakes)as avg_error_count 
	from error_count)
SELECT
	employee_name,
	number_of_mistakes
FROM
	error_count
WHERE	
	number_of_mistakes > (SELECT avg_error_count FROM avg_error_count_per_empl);
    
-- It looks like some of our surveyors are making a lot of "mistakes" while many of the other surveyors are only making a few. I don't like where this is
-- going!

-- cleaning up our code

CREATE VIEW Incorrect_records as(
SELECT v.location_id as visit_location ,v.record_id, v.assigned_employee_id, E.employee_name,
			ar.true_water_source_score as auditor_score,
			wq.subjective_quality_score as surveyor_score,
			ar.statements
FROM auditor_report AS ar
Join visits as v
	on ar.location_id = v.location_id
Join water_quality as wq
	ON v.record_id = wq.record_id
JOIN employee as E
	on v.assigned_employee_id = E.assigned_employee_id
WHERE ar.true_water_source_score != wq.subjective_quality_score
	AND v.visit_count = 1);

with error_count AS( -- CTE calculate number of mistakes each employee made
	select distinct(employee_name) as employee_name, count(assigned_employee_id) as number_of_mistakes
	from Incorrect_records
	group by employee_name
	order by number_of_mistakes ASC),
    
avg_error_count_per_empl AS(
	select AVG(number_of_mistakes)as avg_error_count 
	from error_count),
suspect_list AS(  -- suspect_list has names and number of mistakes for employees who has mistakes more that the average
SELECT
	employee_name,
	number_of_mistakes
FROM
	error_count
WHERE	
	number_of_mistakes > (SELECT avg_error_count FROM avg_error_count_per_empl))

select employee_name , record_id , statements  from Incorrect_records
where employee_name in (select employee_name from suspect_list)
AND statements like '%cash%' 
order by employee_name

-- So we can sum up the evidence we have for Zuriel Matembo, Malachi Mavuso, Bello Azibo and Lalitha Kaburi:
-- 1. They all made more mistakes than their peers on average.
-- 2. They all have incriminating statements made against them, and only them.