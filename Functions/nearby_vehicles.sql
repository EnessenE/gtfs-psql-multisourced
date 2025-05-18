-- FUNCTION: public.search_stop(text)
DROP FUNCTION IF EXISTS public.nearby_vehicles(double precision, double precision, int distance);

CREATE OR REPLACE FUNCTION public.nearby_vehicles(x double precision, y double precision)
    RETURNS TABLE(
        name text,
        stop_type int,
        id text,
        coordinates double precision[])
    LANGUAGE 'sql'
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
    AS $BODY$
    SELECT
        position_entities.last_updated,
        position_entities.id,
        trips.internal_id,
        position_entities.latitude,
        position_entities.longitude,
        position_entities.stop_id,
        position_entities.current_status,
        position_entities.measurement_time,
        position_entities.congestion_level,
        position_entities.occupancy_status,
        position_entities.occupancy_percentage
    FROM
        position_entities
	LEFT JOIN trips ON position_entities.trip_id = trips.id and position_entities.data_origin = trips.data_origin
    WHERE
        ST_DWithin(position_entities.geo_location, ST_MakePoint(x, y), distance, FALSE)
$BODY$;

ALTER FUNCTION public.nearby_vehicles(double precision, double precision) OWNER TO dennis;

SELECT
    *
FROM
    public.nearby_vehicles(51.828813619319, 4.743118421124325, 1000)
