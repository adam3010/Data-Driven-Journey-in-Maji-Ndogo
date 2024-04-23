-- SHOW TABLES--
-- SELECT * FROM location LIMIT 5
-- SELECT * FROM visits LIMIT 5
-- SELECT * FROM water_source LIMIT 5
-- SELECT * FROM data_dictionary 

-- SELECT type_of_water_source FROM water_source group by type_of_water_source
-- SELECT * FROM visits 
-- WHERE time_in_queue > 500

-- SELECT * FROM water_source
-- WHERE source_id in ('AkKi00881224','SoRu37635224','SoRu36096224')


-- SELECT * FROM water_source
-- WHERE source_id in ('AkRu05234224','HaZa21742224')

-- SELECT * FROM water_quality
-- where subjective_quality_score = 10 and visit_count = 2

-- SELECT * FROM well_pollution
-- where biological > 0.01 and results = 'Clean'

-- SELECT * FROM well_pollution
-- where biological > 0.01 and description LIKE 'Clean%'

-- CREATE TABLE 
-- 	md_water_services.well_pollution_copy
--     As(
-- 		SELECT * FROM md_water_services.well_pollution
--     )

-- SELECT * FROM well_pollution_copy
-- where biological > 0.01 and description LIKE 'Clean%'

-- SET SQL_SAFE_UPDATES = 0;

-- UPDATE well_pollution_copy
-- SET description = 'Bacteria: E. coli'
-- WHERE description = 'Clean Bacteria: E. coli'

-- UPDATE well_pollution_copy
-- SET description = 'Bacteria: Giardia Lamblia'
-- WHERE description = 'Clean Bacteria: Giardia Lamblia'

-- UPDATE well_pollution_copy
-- SET results = 'Contaminated: Biological'
-- WHERE biological > 0.01 AND results = 'Clean'

-- UPDATE
-- well_pollution
-- SET
-- description = 'Bacteria: E. coli'
-- WHERE
-- description = 'Clean Bacteria: E. coli';
-- UPDATE
-- well_pollution
-- SET
-- description = 'Bacteria: Giardia Lamblia'
-- WHERE
-- description = 'Clean Bacteria: Giardia Lamblia';
-- UPDATE
-- well_pollution
-- SET
-- results = 'Contaminated: Biological'
-- WHERE
-- biological > 0.01 AND results = 'Clean';
-- DROP TABLE
-- md_water_services.well_pollution_copy;


