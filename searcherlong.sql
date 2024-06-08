DO $$
DECLARE
    temprow RECORD;
    stopdata RECORD;
    stopdata_cursor CURSOR FOR 
        SELECT * 
        FROM stops 
        WHERE NOT EXISTS (
            SELECT 1 
            FROM related_stops 
            WHERE primary_stop = stops.id 
            OR related_stop = stops.id);
    stopdata_count INTEGER;
    current_count INTEGER := 0;
BEGIN
    -- Get the total number of stopdata records
    SELECT COUNT(*) INTO stopdata_count FROM stops 
    WHERE NOT EXISTS (
        SELECT 1 
        FROM related_stops 
        WHERE primary_stop = stops.id 
        OR related_stop = stops.id);

    -- Open the cursor for stopdata
    OPEN stopdata_cursor;
    LOOP
        -- Fetch each record from the cursor
        FETCH stopdata_cursor INTO stopdata;
        EXIT WHEN NOT FOUND;

        -- Increment the current count
        current_count := current_count + 1;

        -- Log progress
        RAISE NOTICE 'Processing record % of %: stopdata ID = %', current_count, stopdata_count, stopdata.id;

        -- Loop through each relevant stop
        FOR temprow IN
            SELECT *
            FROM stops
            WHERE stops.parent_station = stopdata.id OR (ST_DWithin(stops.geo_location, stopdata.geo_location, 1000, FALSE)
            AND SIMILARITY(stopdata.name, stops.name) >= 0.6)
        LOOP
            -- Insert into related_stops
            INSERT INTO public.related_stops(primary_stop, related_stop)
            VALUES (stopdata.id, temprow.id);
        END LOOP;
    END LOOP;
    -- Close the cursor
    CLOSE stopdata_cursor;
END $$;