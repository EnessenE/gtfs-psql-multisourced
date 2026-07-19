CREATE OR REPLACE FUNCTION public.api_get_coverage_from_feeds()
    RETURNS TABLE(
        longitude double precision,
        latitude double precision,
        data_origin text,
        stop_type integer,
        cluster_id integer
)
LANGUAGE 'sql'
COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
AS $BODY$
    WITH clustered AS (
        SELECT
            data_origin,
            stop_type,
            ST_ClusterDBSCAN(
                ST_Transform(geo_location, 3857),
                eps := coalesce(supplier_configurations.coverage_range, 50000),
                minpoints := 1
            ) OVER (
                PARTITION BY data_origin, stop_type
            ) AS cluster_id,
            ST_Transform(geo_location, 3857) AS geom_3857
        FROM stops
        INNER JOIN supplier_configurations on stops.data_origin = supplier_configurations.name
        WHERE stop_type IS NOT NULL
          /* 
             Filter out coordinates that are invalid for EPSG:3857 (Web Mercator).
             Web Mercator is mathematically undefined beyond ~85.05 degrees latitude.
             Filtering prevents the "Invalid coordinate" error during ST_Transform.
          */
          AND ST_X(geo_location) BETWEEN -180 AND 180
          AND ST_Y(geo_location) BETWEEN -85.0511 AND 85.0511
    ),
    hulls AS (
        SELECT
            data_origin,
            stop_type,
            cluster_id,
            ST_ConvexHull(ST_Collect(geom_3857)) AS hull_geom
        FROM clustered
        GROUP BY data_origin, stop_type, cluster_id
    )
    SELECT
        ST_X(ST_Transform(dp.geom, 4326)) AS longitude,
        ST_Y(ST_Transform(dp.geom, 4326)) AS latitude,
        data_origin,
        stop_type,
        cluster_id
    FROM hulls,
        LATERAL ST_DumpPoints(hull_geom) AS dp;

$BODY$;

select * from api_get_coverage_from_feeds();