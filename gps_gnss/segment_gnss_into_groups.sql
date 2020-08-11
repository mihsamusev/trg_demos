--- Segmenting GNSS timeseries data into trips by time
--- Tablename geopoints is holding the datapoints
--- 

/*
-- Add group_id attribute to geopoints table
ALTER TABLE geopoints
ADD COLUMN group_id int;
*/

with basis as (
SELECT 
	indx as idx,  -- Point index
	EXTRACT('epoch' from datetime) as time_in_sec,  -- datetime is timefiled
	datetime,
	device_id,
	geom,
	0 as new_group -- Temporary new group identifier
FROM
	geopoints -- Table keeping GNSS points
WHERE device_id not LIKE '%0#MaintCheck%'
ORDER BY
	device_id,
	indx
LIMIT 1000
), diffs as (
SELECT
	idx,
	time_in_sec-lag(time_in_sec) over(order by device_id,
	idx) as time_diff,
	time_in_sec,
	st_distance(geom::geography, lag(geom::geography) over( order by device_id,
	idx)) as spatial_dist,
	datetime,
	device_id,
	new_group,
	LAG(device_id) over(order by device_id,
	idx) as lag_device_id
FROM
	basis
), when_new_groups as (
SELECT
	idx,
	time_diff,
	spatial_dist,
	datetime,
	device_id,
    CASE
      WHEN
		lag_device_id <> device_id  -- different device
        OR time_diff > 5*60 -- minutes to seconds
        OR time_diff IS NULL
        --OR spatial_dist > 300 -- in meters
        THEN new_group + 1
      ELSE 0
    END AS new_group
FROM diffs ),
groups as (
SELECT
	idx,
	time_diff,
	spatial_dist,
	datetime,
	device_id,
	sum(new_group) OVER (PARTITION by device_id ORDER BY device_id asc, datetime ASC) AS group_id
FROM
	when_new_groups)
UPDATE geopoints SET group_id = groups.group_id FROM groups WHERE geopoints.indx = groups.idx
