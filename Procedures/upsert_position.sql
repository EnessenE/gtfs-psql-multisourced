CREATE OR REPLACE PROCEDURE public.upsert_position(
    _data_origin text,
    _internal_id uuid,
    _last_updated timestamp with time zone,
    _id text,
    _trip_id text,
    _latitude double precision,
    _longitude double precision,
    _stop_id text,
    _current_status text,
    _measurement_time timestamp with time zone,
    _congestion_level text,
    _occupancy_status text,
    _occupancy_percentage integer
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.position_entities (
        data_origin, internal_id, last_updated, id, 
        trip_id, latitude, longitude, geo_location, 
        stop_id, current_status, measurement_time, 
        congestion_level, occupancy_status, occupancy_percentage
    )
    VALUES (
        _data_origin, _internal_id, _last_updated, _id, 
        _trip_id, _latitude, _longitude, ST_SetSRID(ST_MakePoint(_longitude, _latitude), 4326), 
        _stop_id, _current_status, _measurement_time, 
        _congestion_level, _occupancy_status, _occupancy_percentage
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
END;
$$;
