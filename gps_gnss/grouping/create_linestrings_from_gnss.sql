--- Creating linestrings for GNSS timeseries data into trips
--- Tablename tablename is holding the datapoints
--- Tablename trips is holding the linestrings

--- How To:
--- 1. Update tablename with name of table holding the datapoint in ~ line 44

--- 2. Adjust tablelayout in line ~34-43

--- 3. TEST your trips is valid using ST_IsValid:
--- SELECT device_id, group_id FROM trips WHERE ST_IsValid(geom) == False


DROP TABLE IF EXISTS trips;
CREATE TABLE trips (
    device_id varchar(255),
    group_id bigint,
    trip_id uuid,
    start_date timestamp without time zone,
    end_date timestamp without time zone,
    geom geometry(LINESTRINGZM, 4326), -- wgs84 = 4326, euref89-utm32 = 25832
    length double precision,
    min_point_id bigint,
    max_point_id bigint,
	PRIMARY KEY (device_id, group_id)
);

CREATE INDEX on trips USING GIST(geom);


INSERT INTO trips
WITH gps as (
SELECT
                DISTINCT ON (device_id, datetime) indx,
                0 as group_id,
                '12345678-123d-4321-a123-123456789abc'::uuid as trip_id,
                device_id,
                datetime,
                geom AS geom,
				st_setsrid(st_makepoint(ST_X(geom),
							 ST_Y(geom),
							 indx, -- index as Z value
							 extract(epoch from datetime)), 4326) as geomZM
        FROM tablename
		-- where device_id = 'WSM00000003286085'
)
SELECT
    device_id,
    group_id,
    trip_id,
    min(datetime) as start_date,
    max(datetime) as end_date,
    ST_MakeLine(geomZM order by datetime ASC) as geom,
    ST_Length(ST_MakeLine(geomZM order by datetime ASC), true) As length,
    min(indx)::bigint as min_punkt_no,
    max(indx)::bigint as max_punkt_no
FROM gps
GROUP BY device_id, group_id, trip_id
HAVING COUNT(indx) > 1 ORDER BY device_id, gps.group_id
