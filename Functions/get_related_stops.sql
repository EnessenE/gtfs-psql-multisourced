CREATE OR REPLACE FUNCTION public.get_related_stops(target text, target_stop_type int)
    RETURNS TABLE(
        id text,
        name text,
        stop_type int)
    LANGUAGE 'sql'
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
    AS $BODY$
    WITH stop_data AS(
        SELECT 
            related_stop
        FROM
            related_stops
        WHERE
            lower(primary_stop) = lower(target) limit 1)
    SELECT distinct
		primary_stop id,
        name,
        stop_type
    FROM
        related_stops
        INNER JOIN stops ON related_stops.related_stop = stops.id and related_stops.related_data_origin = stops.data_origin
    WHERE(lower(primary_stop) = lower(target))
    AND (stop_type != target_stop_type AND stop_type != 1000 )
$BODY$;

ALTER FUNCTION public.get_related_stops(text) OWNER TO dennis;
SELECT
    *
FROM
    public.get_related_stops('2510141')
