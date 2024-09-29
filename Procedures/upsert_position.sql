
drop PROCEDURE upsert_position_array(position_entity_type[]);
drop type position_entity_type;

CREATE TYPE public.position_entity_type AS (
    data_origin text,
    internal_id uuid,
    last_updated timestamp with time zone,
    id text,
    trip_id text,
    latitude double precision,
    longitude double precision,
    stop_id text,
    current_status text,
    measurement_time timestamp with time zone,
    congestion_level text,
    occupancy_status text,
    occupancy_percentage integer
);


CREATE OR REPLACE PROCEDURE public.upsert_position_array(
    positions public.position_entity_type[]
)
LANGUAGE plpgsql
AS $$
DECLARE
    position public.position_entity_type;
BEGIN
    FOREACH position IN ARRAY positions
    LOOP
        INSERT INTO public.position_entities (id, 
            data_origin, internal_id, last_updated, 
            trip_id, latitude, longitude, geo_location, 
            stop_id, current_status, measurement_time, 
            congestion_level, occupancy_status, occupancy_percentage
        )
        VALUES (position.id,
            position.data_origin, position.internal_id, position.last_updated, 
            position.trip_id, position.latitude, position.longitude, 
            ST_SetSRID(ST_MakePoint(position.longitude, position.latitude), 4326), 
            position.stop_id, position.current_status, position.measurement_time, 
            position.congestion_level, position.occupancy_status, position.occupancy_percentage
        )
        ON CONFLICT (data_origin, id) 
        DO UPDATE SET 
            last_updated = EXCLUDED.last_updated,
            trip_id = EXCLUDED.trip_id,
            latitude = EXCLUDED.latitude,
            longitude = EXCLUDED.longitude,
            geo_location = EXCLUDED.geo_location,
            stop_id = EXCLUDED.stop_id,
            current_status = EXCLUDED.current_status,
            measurement_time = EXCLUDED.measurement_time,
            congestion_level = EXCLUDED.congestion_level,
            occupancy_status = EXCLUDED.occupancy_status,
            occupancy_percentage = EXCLUDED.occupancy_percentage;
    END LOOP;
END;
$$;