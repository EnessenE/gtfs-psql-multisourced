CREATE OR REPLACE PROCEDURE public.merge_stop(IN target text, IN supplier text)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    stopdata RECORD;
    temprow RECORD;
    chosen_guid uuid;
BEGIN
    -- Generate a UUID for this merge session
    SELECT uuid_generate_v4()::uuid INTO chosen_guid;
    
    -- Get stopdata record, ensuring it's not already related
    SELECT * INTO stopdata
    FROM stops
    WHERE id = target
      AND data_origin = supplier
      AND NOT EXISTS (
          SELECT 1
          FROM related_stops
          INNER JOIN stops ON stops.internal_id = related_stops.related_stop
          WHERE stops.id = target
            AND related_data_origin = supplier
      );
    
    IF NOT FOUND THEN
        RAISE NOTICE 'Target stop does not exist or is already related.';
        RETURN;
    END IF;
    
    -- Loop through each relevant stop
    FOR temprow IN
        SELECT *
        FROM stops
        WHERE (
            ((stopdata.parent_station = stops.id AND stopdata.data_origin = stops.data_origin)
            OR (stops.id = stopdata.parent_station AND stopdata.data_origin = stops.data_origin))
            OR ((
                ST_DWithin(stops.geo_location, stopdata.geo_location, 75, FALSE)
                OR (ST_DWithin(stops.geo_location, stopdata.geo_location, 300, FALSE) 
                    AND SIMILARITY(stopdata.name, stops.name) >= 0.2)
                OR (ST_DWithin(stops.geo_location, stopdata.geo_location, 350, FALSE) 
                    AND SIMILARITY(stopdata.name, stops.name) >= 0.3)
                OR (ST_DWithin(stops.geo_location, stopdata.geo_location, 400, FALSE) 
                    AND SIMILARITY(stopdata.name, stops.name) >= 0.6)
                OR (ST_DWithin(stops.geo_location, stopdata.geo_location, 3000, FALSE) 
                    AND SIMILARITY(stopdata.name, stops.name) >= 0.9)
            ) AND (stopdata.parent_station IS NULL ) )
        )
    LOOP
        -- Check if temprow is already a related_stop in the related_stops table
        IF EXISTS (
            SELECT 1
            FROM related_stops
            WHERE related_stop = temprow.internal_id
        ) THEN
            -- Insert into related_stops using the primary_stop of the existing relation
            INSERT INTO public.related_stops(primary_stop, related_stop, related_data_origin)
                VALUES (
                    (SELECT primary_stop
                     FROM related_stops
                     WHERE related_stop = temprow.internal_id
                     LIMIT 1),
                    stopdata.internal_id,
                    stopdata.data_origin
                )
            ON CONFLICT DO NOTHING;
            RETURN;
        ELSE
            -- Insert into related_stops using the chosen GUID for new relations
            INSERT INTO public.related_stops(primary_stop, related_stop, related_data_origin)
                VALUES (chosen_guid, temprow.internal_id, temprow.data_origin)
            ON CONFLICT DO NOTHING;
        END IF;
    END LOOP;
END;
$BODY$;

ALTER PROCEDURE public.merge_stop(text, text) OWNER TO dennis;
