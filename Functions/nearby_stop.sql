-- FUNCTION: public.search_stop(text)
DROP FUNCTION IF EXISTS public.nearby_stops(double precision, double precision);

CREATE OR REPLACE FUNCTION public.nearby_stops(x double precision, y double precision)
    RETURNS TABLE(
        name text,
        stop_type int,
        id text,
        longitude double precision,
        latitude double precision,
		distance_in_meters int)
    LANGUAGE 'sql'
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
    AS $BODY$
    WITH found_primaries AS (SELECT DISTINCT
        primary_stop,
		stop_type
    FROM
        public.related_stops
        INNER JOIN stops ON related_stops.related_stop = stops.internal_id
    WHERE
        ST_DWithin(stops.geo_location, ST_MakePoint(x, y), 3000, FALSE)
	GROUP BY primary_stop, stop_type)
    select         
            stops.name,
            stops.stop_type,
            primary_stop as id,
            longitude,
            latitude,
			(SELECT ST_DistanceSphere(stops.geo_location, ST_MakePoint(x, y, 3857)) as distance_meters)
	from stops
    INNER JOIN related_stops ON related_stops.related_stop = stops.internal_id
    where related_stops.primary_stop in (select primary_stop from found_primaries)
    ORDER BY (SELECT ST_DistanceSphere(stops.geo_location, ST_MakePoint(x, y))) ASC
    LIMIT 100;
$BODY$;

ALTER FUNCTION public.nearby_stops(double precision, double precision) OWNER TO dennis;

SELECT
    *
FROM
    public.nearby_stops(51.794179, 4.653556)
