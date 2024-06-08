
DO $$
DECLARE
    temprow RECORD;
    stopdata RECORD;
BEGIN
    -- Get stopdata record
    SELECT *
    INTO stopdata
    FROM stops
    WHERE NOT EXISTS (
        SELECT 1
        FROM related_stops
        WHERE primary_stop = stops.id
        OR related_stop = stops.id
    );

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
END $$;
