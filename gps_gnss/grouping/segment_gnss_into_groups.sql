--- Segmenting GNSS timeseries data into trips by time
--- Tablename tablename is holding the datapoints
--- 

--- Updating a large table of data is timeconsuming, so the original table is copied to tablename_old
--- Then a new table is created with tablename_old but with a new column group_id

--- How To:
--- 1. Update tablename with name of table holding the datapoint in ~ line 12, 13, 15, 31, 78 and 79

--- 2. Move original table to suffix _old:
--- ALTER TABLE tablename RENAME tablename TO tablename_old;

--- 3. Create new table like original, but with group_id column
--- CREATE TABLE IF NOT EXISTS tablename ( LIKE tablename_old including all, group_id int)

--- 4. Run the code from line 22

--- 5. If succeded, then delete tablename_old
--- DROP TABLE IF EXIST tablename_old;

with basis as (
select
	indx as idx,  -- Point index
	extract('epoch' from datetime) AS time_in_sec,  -- datetime is timefiled
	datetime AS datetime,
	device_id AS device_id,
	geom AS geom,
	0 as new_group -- Temporary new group identifier
FROM
	tablename -- Table keeping GNSS points
order by
	device_id,
	indx
), diffs as (
select
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
select
	idx,
	time_diff,
	spatial_dist,
	datetime,
	device_id,
	/* When to start a new group? */
    case
      when
		lag_device_id <> device_id  -- different device
        or time_diff > 5*60 -- minutes to seconds
        or time_diff is null
        --OR spatial_dist > 300 -- in meters
        then new_group + 1
      else 0
    end as new_group
from diffs ),
g as (
select
	idx,
	time_diff,
	spatial_dist,
	datetime,
	device_id,
	sum(new_group) over (partition by device_id order by device_id asc, datetime asc) as group_id
from
	when_new_groups)
insert into tablename
select org.*, g.group_id::int FROM tablename_old as org JOIN g ON org.indx = g.idx

