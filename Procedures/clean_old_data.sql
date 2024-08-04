-- PROCEDURE: public.merge_stop(text, text)
-- DROP PROCEDURE IF EXISTS public.merge_stop(text, text);
CREATE OR REPLACE PROCEDURE public.clean_old_data()
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    DELETE FROM related_stops
    WHERE related_stop = ANY(ARRAY(
                SELECT
                    related_stop
                FROM
                    related_stops
                LEFT JOIN stops ON stops.internal_id = related_stops.related_stop
            WHERE
                stops.id IS NULL));
END;
$BODY$;

ALTER PROCEDURE public.clean_old_data() OWNER TO dennis;

