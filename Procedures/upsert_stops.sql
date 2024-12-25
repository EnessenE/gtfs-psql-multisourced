CREATE OR REPLACE PROCEDURE public.upsert_stops(
    stops public.stops_type
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.stops(
        data_origin, id, code, name, description, latitude, longitude, geo_location, zone, url, location_type, parent_station, timezone, wheelchair_boarding, level_id, platform_code, stop_type, internal_id, last_updated, import_id
    )
    SELECT data_origin, id, code, name, description, latitude, longitude, geo_location, zone, url, location_type, parent_station, timezone, wheelchair_boarding, level_id, platform_code, stop_type, internal_id, last_updated, import_id
    FROM stops
    ON CONFLICT(id, data_origin) DO UPDATE
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