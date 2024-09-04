drop procedure upsert_trip_update_array(trip_update_type[]);
drop type trip_update_type;
CREATE TYPE trip_update_type AS (
    data_origin text,
    internal_id uuid,
    id text,
    last_updated timestamp with time zone,
    delay int,
    measurement_time timestamp with time zone
);


CREATE OR REPLACE PROCEDURE upsert_trip_update_array(IN updates trip_update_type[])
LANGUAGE plpgsql
AS $$
DECLARE
    update_item trip_update_type;
BEGIN
    -- Loop through the array of trip_update_type
    FOREACH update_item IN ARRAY updates LOOP
        INSERT INTO trip_updates(data_origin, internal_id, id, last_updated, delay, measurement_time)
            VALUES (update_item.data_origin, update_item.internal_id, update_item.id, update_item.last_updated, update_item.delay, update_item.measurement_time)
        ON CONFLICT (data_origin, id)
            DO UPDATE SET
                data_origin = EXCLUDED.data_origin, last_updated = EXCLUDED.last_updated, delay = EXCLUDED.delay, measurement_time = EXCLUDED.measurement_time;
    END LOOP;
END
$$;

