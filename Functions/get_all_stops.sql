CREATE OR REPLACE FUNCTION public.get_all_stops()
    RETURNS TABLE(
        primary_stop text,
        name text,
        latitude double precision,
        longitude double precision)
    LANGUAGE 'sql'
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
    AS $BODY$
    SELECT
        related_stops.primary_stop,
        name,
        latitude,
        longitude
    FROM
        stops
        INNER JOIN related_stops ON related_stops.related_stop = stops.internal_id
$BODY$;

ALTER FUNCTION public.get_all_stops() OWNER TO dennis;

