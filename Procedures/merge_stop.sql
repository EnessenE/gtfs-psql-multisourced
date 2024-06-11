-- PROCEDURE: public.merge_stop(text, text)
-- DROP PROCEDURE IF EXISTS public.merge_stop(text, text);
CREATE OR REPLACE PROCEDURE public.merge_stop(IN target text, IN supplier text)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    stopdata RECORD;
    temprow RECORD;
BEGIN
    -- Get stopdata record
    SELECT
        * INTO stopdata
    FROM
        stops
    WHERE
        id = target
        AND data_origin = supplier
        AND NOT EXISTS (
            SELECT
                1
            FROM
                related_stops
            WHERE (primary_stop = target
                OR related_stop = target));
    IF NOT FOUND THEN
        RAISE NOTICE 'Target stop does not exist or is already related.';
        RETURN;
    END IF;
    -- Loop through each relevant stop
    FOR temprow IN
    SELECT
        *
    FROM
        stops
    WHERE ((stops.parent_station = stopdata.id
        OR stops.id = stopdata.parent_station)
        OR ((ST_DWithin(stops.geo_location, stopdata.geo_location, 50, FALSE))
        OR
            (ST_DWithin(stops.geo_location, stopdata.geo_location, 300, FALSE)
            AND SIMILARITY(stopdata.name, stops.name) >= 0.3)
        OR 
            (ST_DWithin(stops.geo_location, stopdata.geo_location, 400, FALSE)
            AND SIMILARITY(stopdata.name, stops.name) >= 0.6)
        OR 
            (ST_DWithin(stops.geo_location, stopdata.geo_location, 3000, FALSE)
            AND SIMILARITY(stopdata.name, stops.name) >= 0.9))
            )
    --AND stopdata.stop_type = stops.stop_type
    LOOP
        -- Check if temprow is already a related_stop in the related_stops table
        IF EXISTS (
            SELECT
                1
            FROM
                related_stops
            WHERE
                related_stop = temprow.id) THEN
        -- Update the primary_stop to the target stop
            INSERT INTO public.related_stops(primary_stop, primary_data_origin, related_stop, related_data_origin)
                VALUES (temprow.id, temprow.data_origin, stopdata.id, stopdata.data_origin);
        ELSE
            -- Insert into related_stops
            INSERT INTO public.related_stops(primary_stop, primary_data_origin, related_stop, related_data_origin)
                VALUES (stopdata.id, stopdata.data_origin, temprow.id, temprow.data_origin)
        ON CONFLICT
            DO NOTHING;
    END IF;
END LOOP;
END;
$BODY$;

ALTER PROCEDURE public.merge_stop(text, text) OWNER TO dennis;

