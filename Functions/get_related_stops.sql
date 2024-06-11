CREATE OR REPLACE FUNCTION public.get_related_stops(target text)
    RETURNS TABLE(
        id text,
        name text,
        stop_type int)
    LANGUAGE 'sql'
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
    AS $BODY$
    WITH stop_data AS(
        SELECT 
            id,
            stop_type
        FROM
            stops
        WHERE
            lower(id) = lower(target))
    SELECT distinct
		primary_stop id,
        name,
        stop_type
    FROM
        related_stops
        INNER JOIN stops ON related_stops.related_stop = stops.id
    WHERE(lower(primary_stop) = lower(target)
        OR lower(related_stop) = lower(target))
    AND stop_type !=(
        SELECT
            stop_type
        FROM
            stop_data)
$BODY$;

ALTER FUNCTION public.get_related_stops(text) OWNER TO dennis;
SELECT
    *
FROM
    public.get_related_stops('2510141')
