--Create copy of the trails table where the status is open
CREATE TABLE trails_open AS 
	SELECT * 
	FROM trails
	WHERE status = 'Open';
	
SELECT * FROM trails_open;

--Create buffer of 1320 feet and use ST_Union to make it one feature
DROP VIEW trail_buffer CASCADE;
CREATE VIEW trail_buffer as
SELECT ST_Union(ST_Buffer(geom, 1320)) as geom
FROM trails_open;

--Create copy of the blockgrp2010 table
DROP TABLE blockpop;
CREATE TABLE blockpop AS
	SELECT tract, fips, pop10, white, black, aian, asian, other_race, pop_2_race, hispanic, geom  
	FROM blockgrp2010;
	
SELECT * FROM blockpop;

--Find the proportioaln rate between the area with trail access and the blockgroup
DROP VIEW IF EXISTS blockpop_prop CASCADE;
CREATE VIEW blockpop_prop AS
SELECT bg.fips, bg.pop10, bg.white, bg.black, bg.aian, bg.asian, bg.other_race, bg.pop_2_race, bg.hispanic,
ST_Area(ST_Intersection(tb.geom, bg.geom))/ST_Area(bg.geom) as Proportion
FROM blockpop AS bg, trail_buffer AS tb
WHERE ST_Intersects(tb.geom,bg.geom)
ORDER BY fips, Proportion DESC;

-- Get the population for each demographic group with trail access
DROP VIEW block_accessPop;
CREATE VIEW  block_accessPop AS
SELECT fips, SUM(Proportion*pop10)::int as PopAccess, SUM(Proportion*white)::int AS PopAccess_white,
SUM(Proportion*black)::int AS PopAccess_black, SUM(Proportion*aian)::int AS PopAccess_aian,
SUM(Proportion*asian)::int AS PopAccess_asian, SUM(Proportion*other_race)::int AS PopAccess_other_race,
SUM(Proportion*pop_2_race)::int AS PopAccess_pop_2_race, SUM(Proportion*hispanic)::int AS PopAccess_hispanic
FROM blockpop_prop
GROUP BY fips;

-- Join the block_AccessPop and  blockpop_prop tables on the fipscolumn
CREATE VIEW block_accessPopPerc AS 
SELECT ba_pop.fips, popaccess, pop10, 
PopAccess_white, white, 
PopAccess_black, black, 
PopAccess_aian, aian, 
PopAccess_asian, asian,
PopAccess_other_race, other_race,
PopAccess_pop_2_race, pop_2_race,
PopAccess_hispanic, hispanic
FROM
block_accessPop as ba_pop
LEFT JOIN blockpop_prop bprop
ON ba_pop.fips = bprop.fips


--Create a view for the final results table DemoTrailAccess which shows the percent of the 
--population for each demographic group that have trail access
CREATE VIEW DemoTrailAcesss AS
SELECT (SUM(popaccess)::float)/(SUM(pop10)::float)*100 AS TotalPopAccess_Percent,
(SUM(popaccess_white)::float)/(SUM(white)::float)*100 AS TotalPopAccessWhite_Percent,
(SUM(popaccess_black)::float)/(SUM(black)::float)*100 AS TotalPopAccessBlack_Percent,
(SUM(popaccess_aian)::float)/(SUM(aian)::float)*100 AS TotalPopAccessAian_Percent,
(SUM(popaccess_asian)::float)/(SUM(asian)::float)*100 AS TotalPopAccessAsian_Percent,
(SUM(popaccess_other_race)::float)/(SUM(other_race)::float)*100 AS TotalPopAccessOtherRace_Percent,
(SUM(popaccess_pop_2_race)::float)/(SUM(pop_2_race)::float)*100 AS TotalPopAccess2Race_Percent,
(SUM(popaccess_hispanic)::float)/(SUM(hispanic)::float)*100 AS TotalPopAccessHispanic_Percent
FROM block_accessPopPerc;
--Print population for each demographic group that have trail access
SELECT * FROM DemoTrailAcesss;

