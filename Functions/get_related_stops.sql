CREATE OR REPLACE FUNCTION public.get_related_stops(target uuid, target_stop_type int)
    RETURNS TABLE(
        id text,
        name text,
        stop_type int)
    LANGUAGE 'sql'
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
    AS $BODY$
	WITH stop_data AS(
		SELECT 
			primary_stop, geo_location
		FROM
			related_stops	
			INNER JOIN stops ON related_stops.related_stop = stops.internal_id and related_stops.related_data_origin = stops.data_origin
		WHERE
			primary_stop = target
		limit 1)
	SELECT
		primary_stop id,
		name,
		stop_type
	FROM
		stops
	INNER JOIN related_stops ON related_stops.related_stop = stops.internal_id
	WHERE
	(ST_DWithin(stops.geo_location, (select geo_location from stop_data limit 1), 800, FALSE))
	AND stop_type IS NOT NULL
	AND NOT primary_stop = target
$BODY$;
