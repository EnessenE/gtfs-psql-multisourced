DROP PROCEDURE IF EXISTS public.upsert_stops;

CREATE OR REPLACE PROCEDURE public.upsert_stops(
    _stops public.stops_type[]
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.stops(
        data_origin, id, code, name, description, latitude, longitude, geo_location, zone, url, location_type, parent_station, timezone, wheelchair_boarding, level_id, platform_code, stop_type, internal_id, last_updated, import_id
    )
    SELECT 
        _stop.data_origin, 
        _stop.id, 
        _stop.code, 
        _stop.name, 
        _stop.description, 
        _stop.latitude, 
        _stop.longitude, 
        ST_SetSRID(ST_MakePoint(_stop.longitude, _stop.latitude), 4326), 
        _stop.zone, 
        _stop.url, 
        _stop.location_type_data, 
        _stop.parent_station, 
        _stop.timezone, 
        _stop.wheelchair_boarding_data, 
        _stop.level_id, 
        _stop.platform_code, 
        _stop.stop_type_data, 
        _stop.internal_id, 
        _stop.last_updated, 
        _stop.import_id
    FROM UNNEST(_stops) AS _stop
    ON CONFLICT (id, data_origin) DO UPDATE
    SET 
        data_origin = EXCLUDED.data_origin,
        code = EXCLUDED.code,
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        latitude = EXCLUDED.latitude,
        longitude = EXCLUDED.longitude,
        geo_location = EXCLUDED.geo_location,
        zone = EXCLUDED.zone,
        url = EXCLUDED.url,
        location_type = EXCLUDED.location_type,
        parent_station = EXCLUDED.parent_station,
        timezone = EXCLUDED.timezone,
        wheelchair_boarding = EXCLUDED.wheelchair_boarding,
        level_id = EXCLUDED.level_id,
        platform_code = EXCLUDED.platform_code,
        stop_type = EXCLUDED.stop_type,
        internal_id = EXCLUDED.internal_id,
        last_updated = EXCLUDED.last_updated,
        import_id = EXCLUDED.import_id;
END;
$$;
