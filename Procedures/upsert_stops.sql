DROP PROCEDURE IF EXISTS public.upsert_stops;

CREATE OR REPLACE PROCEDURE public.upsert_stops(
    _stops public.stops_type[]
)
LANGUAGE plpgsql
AS $$
BEGIN
    MERGE INTO public.stops AS target
    USING (
        SELECT DISTINCT
            _stop.data_origin, 
            _stop.id, 
            _stop.code, 
            _stop.name, 
            _stop.description, 
            _stop.latitude, 
            _stop.longitude, 
            ST_SetSRID(ST_MakePoint( 
                _stop.longitude,
                _stop.latitude), 4326) AS geo_location, 
            _stop.zone, 
            _stop.url, 
            _stop.location_type_data AS location_type, 
            _stop.parent_station, 
            _stop.timezone, 
            _stop.wheelchair_boarding_data AS wheelchair_boarding, 
            _stop.level_id, 
            _stop.platform_code, 
            _stop.stop_type_data AS stop_type, 
            _stop.internal_id, 
            _stop.last_updated, 
            _stop.import_id
        FROM UNNEST(_stops) AS _stop
    ) AS source
    ON target.id = source.id AND target.data_origin = source.data_origin
    WHEN MATCHED THEN
        UPDATE SET
            -- Only update fields that need to change
            code = source.code,
            name = source.name,
            description = source.description,
            latitude = source.latitude,
            longitude = source.longitude,
            geo_location = COALESCE(target.geo_location, source.geo_location), -- Do not overwrite geo_location if already set
            zone = source.zone,
            url = source.url,
            location_type = source.location_type,
            parent_station = source.parent_station,
            timezone = source.timezone,
            wheelchair_boarding = source.wheelchair_boarding,
            level_id = source.level_id,
            platform_code = source.platform_code,
            stop_type = source.stop_type,
            internal_id = source.internal_id,
            last_updated = source.last_updated,
            import_id = source.import_id
    WHEN NOT MATCHED THEN
        INSERT (
            data_origin, id, code, name, description, latitude, longitude, geo_location, zone, url, location_type, parent_station, timezone, wheelchair_boarding, level_id, platform_code, stop_type, internal_id, last_updated, import_id
        )
        VALUES (
            source.data_origin, 
            source.id, 
            source.code, 
            source.name, 
            source.description, 
            source.latitude, 
            source.longitude, 
            source.geo_location, 
            source.zone, 
            source.url, 
            source.location_type, 
            source.parent_station, 
            source.timezone, 
            source.wheelchair_boarding, 
            source.level_id, 
            source.platform_code, 
            source.stop_type, 
            source.internal_id, 
            source.last_updated, 
            source.import_id
        );
END;
$$;
