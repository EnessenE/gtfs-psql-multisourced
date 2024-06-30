-- PROCEDURE: public.merge_stop(text, text)
-- DROP PROCEDURE IF EXISTS public.merge_stop(text, text);
CREATE OR REPLACE PROCEDURE public.merge_stop(IN target text, IN supplier text)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    stopdata RECORD;
    temprow RECORD;
    chosen_guid uuid;
BEGIN
    SELECT
        uuid_generate_v4() INTO chosen_guid;
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
            inner join stops on stops.internal_id = related_stops.related_stop
            WHERE (stops.id = target
                AND related_data_origin = supplier));
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
            OR (ST_DWithin(stops.geo_location, stopdata.geo_location, 300, FALSE)
                AND SIMILARITY(stopdata.name, stops.name) >= 0.3)
            OR (ST_DWithin(stops.geo_location, stopdata.geo_location, 400, FALSE)
                AND SIMILARITY(stopdata.name, stops.name) >= 0.6)
            OR (ST_DWithin(stops.geo_location, stopdata.geo_location, 3000, FALSE)
                AND SIMILARITY(stopdata.name, stops.name) >= 0.9)))
    --AND stopdata.stop_type = stops.stop_type
    LOOP
        -- Check if temprow is already a related_stop in the related_stops table
        IF EXISTS (
            SELECT
                1
            FROM
                related_stops
            WHERE
                related_stop = temprow.internal_id) THEN
        RAISE NOTICE 'Inserting: %',(
            SELECT
                primary_stop
            FROM
                related_stops
            WHERE
                related_stop = temprow.internal_id
            LIMIT 1);
        -- Add from the primary_stop for the target stop
        INSERT INTO public.related_stops(primary_stop, related_stop, related_data_origin)
            VALUES ((
                    SELECT
                        primary_stop
                    FROM
                        related_stops
                    WHERE
                        related_stop = temprow.internal_id
                    LIMIT 1),
                stopdata.id,
                stopdata.data_origin);
        RETURN;
    ELSE
        -- Insert into related_stops
        INSERT INTO public.related_stops(primary_stop, related_stop, related_data_origin)
            VALUES (chosen_guid, temprow.internal_id, temprow.data_origin)
        ON CONFLICT
            DO NOTHING;
    END IF;
END LOOP;
END;
$BODY$;

ALTER PROCEDURE public.merge_stop(text, text) OWNER TO dennis;

CALL public.merge_stop('2612455', 'OpenOV')
