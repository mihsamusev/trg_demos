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
--- CREATE TABLE IF NOT EXISTS tablename ( LIKE tablename_old including all, group_id int, ident uuid)

--- 4. Run the code from line 22

--- 5. If succeded, then delete tablename_old
--- DROP TABLE IF EXIST tablename_old;

WITH basis AS (
    SELECT
        indx AS idx,  -- Point index
        extract('epoch' from datetime) AS time_in_sec,  -- datetime is timefiled
        datetime AS datetime,
        device_id AS device_id,
        geom AS geom,
        0 AS new_group -- Temporary new group identifier
    FROM
        tablename_old -- Table keeping GNSS points
    ORDER BY
        device_id,
        indx
), diffs AS (
    SELECT
        idx,
        time_in_sec-lag(time_in_sec) over(order by device_id,
        idx) AS time_diff,
        time_in_sec,
        st_distance(geom::geography, lag(geom::geography) over( order by device_id,
        idx)) AS spatial_dist,
        datetime,
        device_id,
        new_group,
        LAG(device_id) over(order by device_id,
        idx) AS lag_device_id
    FROM
        basis
), when_new_groups as (
    SELECT
        idx,
        time_diff,
        spatial_dist,
        datetime,
        device_id,
        /* When to start a new group? */
        CASE
          WHEN
            lag_device_id <> device_id  -- different device
            OR time_diff > 5*60 -- minutes to seconds
            OR time_diff IS NULL
            --OR spatial_dist > 300 -- in meters
            then new_group + 1
          ELSE 0
        END AS new_group
    FROM
    diffs
), g AS (
    SELECT
        idx,
        time_diff,
        spatial_dist,
        datetime,
        device_id,
        sum(new_group) OVER (partition by device_id order by device_id asc, datetime asc) AS group_id
    FROM
        when_new_groups
), g_uuid AS (
    SELECT
        uuid_in(md5(g.device_id || g.group_id::text  || random())::cstring) AS ident,
        device_id,
        group_id
    FROM g
    GROUP BY device_id, group_id
)

INSERT INTO tablename
SELECT
    org.*,
    g.group_id::int,
    g_uuid.ident
FROM
    tablename_old as org JOIN g
        ON org.indx = g.idx JOIN g_uuid
        ON g.device_id = g_uuid.device_id and g.group_id = g_uuid.group_id