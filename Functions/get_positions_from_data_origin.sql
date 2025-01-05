-- FUNCTION: public.get_positions_from_data_origin(text)

-- DROP FUNCTION IF EXISTS public.get_positions_from_data_origin(text);

CREATE OR REPLACE FUNCTION public.get_positions_from_data_origin(
	target_data_origin text)
    RETURNS TABLE(last_updated timestamp with time zone, id text, trip_id text, latitude double precision, longitude double precision, stop_id text, current_status text, measurement_time timestamp with time zone, congestion_level text, occupancy_status text, occupancy_percentage integer) 
    LANGUAGE 'sql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

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
        position_entities.data_origin = target_data_origin
$BODY$;

ALTER FUNCTION public.get_positions_from_data_origin(text)
    OWNER TO postgres;


select * from get_positions_from_data_origin('OpenOV')