drop procedure upsert_trip_update_array_stop_time(trip_update_stop_time_type[]);
drop type trip_update_stop_time_type;

CREATE TYPE trip_update_stop_time_type AS (
    data_origin text,
    internal_id uuid,
    last_updated timestamp WITH time zone,
    stop_sequence int,
    stop_id text,
    trip_id text,
    arrival_delay int,
    arrival_time timestamp with time zone,
    arrival_uncertainty int,
    departure_delay int,
    departure_time timestamp with time zone,
    departure_uncertainty int,
    schedule_relationship text
);


CREATE OR REPLACE PROCEDURE public.upsert_trip_update_array_stop_time(
    IN updates trip_update_stop_time_type[]
)
LANGUAGE plpgsql
AS $$
DECLARE
    update_item trip_update_stop_time_type;
BEGIN
    -- Loop through the array and insert each record into the table
    FOREACH update_item IN ARRAY updates LOOP
        INSERT INTO trip_updates_stop_times (
            data_origin,
            internal_id,
            last_updated,
            stop_sequence,
            trip_id,
            stop_id,
            arrival_delay,
            arrival_time,
            arrival_uncertainty,
            departure_delay,
            departure_time,
            departure_uncertainty,
            schedule_relationship
        )
        VALUES (
            update_item.data_origin,
            update_item.internal_id,
            update_item.last_updated,
            update_item.stop_sequence,
            update_item.trip_id,
            update_item.stop_id,
            update_item.arrival_delay,
            update_item.arrival_time,
            update_item.arrival_uncertainty,
            update_item.departure_delay,
            update_item.departure_time,
            update_item.departure_uncertainty,
            update_item.schedule_relationship
        )
        ON CONFLICT (data_origin, stop_id, trip_id) DO UPDATE
        SET
            data_origin = EXCLUDED.data_origin,
            last_updated = EXCLUDED.last_updated,
            stop_sequence = EXCLUDED.stop_sequence,
            stop_id = EXCLUDED.stop_id,
            arrival_delay = EXCLUDED.arrival_delay,
            arrival_time = EXCLUDED.arrival_time,
            arrival_uncertainty = EXCLUDED.arrival_uncertainty,
            departure_delay = EXCLUDED.departure_delay,
            departure_time = EXCLUDED.departure_time,
            departure_uncertainty = EXCLUDED.departure_uncertainty,
            schedule_relationship = EXCLUDED.schedule_relationship;
    END LOOP;
END;
$$;