drop procedure if exists upsert_trip_updates(trip_update_type[]);
drop type trip_update_type;
CREATE TYPE trip_update_type AS (
    data_origin text,
    internal_id uuid,
    id text,
    trip_id text,
    last_updated timestamp with time zone,
    delay int,
    schedule_relationship text,
    vehicle_id text,
    vehicle_label text,
    vehicle_license_plate text,
    vehicle_wheelchair_accessible text,
    measurement_time timestamp with time zone
);


CREATE OR REPLACE PROCEDURE upsert_trip_updates(IN updates trip_update_type[])
LANGUAGE plpgsql
AS $$
DECLARE
    update_item trip_update_type;
BEGIN
    -- Loop through the array of trip_update_type
    FOREACH update_item IN ARRAY updates LOOP
        INSERT INTO trip_updates(data_origin, internal_id, id, trip_id, last_updated, delay, schedule_relationship, vehicle_id, vehicle_label, vehicle_license_plate, vehicle_wheelchair_accessible, measurement_time)
            VALUES (update_item.data_origin, update_item.internal_id, update_item.id, update_item.trip_id, update_item.last_updated, update_item.delay, update_item.schedule_relationship, update_item.vehicle_id, update_item.vehicle_label, update_item.vehicle_license_plate, update_item.vehicle_wheelchair_accessible, update_item.measurement_time)
        ON CONFLICT (data_origin, id)
            DO UPDATE SET
                data_origin = EXCLUDED.data_origin,
                trip_id = EXCLUDED.trip_id,
                last_updated = EXCLUDED.last_updated,
                delay = EXCLUDED.delay,
                measurement_time = EXCLUDED.measurement_time,
                schedule_relationship = EXCLUDED.schedule_relationship,
                vehicle_id = EXCLUDED.vehicle_id,
                vehicle_label = EXCLUDED.vehicle_label,
                vehicle_license_plate = EXCLUDED.vehicle_license_plate,
                vehicle_wheelchair_accessible = EXCLUDED.vehicle_wheelchair_accessible;
    END LOOP;
END
$$;

