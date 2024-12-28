DROP PROCEDURE IF EXISTS public.upsert_trips;

CREATE OR REPLACE PROCEDURE public.upsert_trips(
    _trips public.trips_type[]
)
LANGUAGE plpgsql
AS $$
BEGIN
    MERGE INTO public.trips AS target
    USING (
        SELECT DISTINCT
            _trip.data_origin, 
            _trip.id, 
            _trip.route_id, 
            _trip.service_id, 
            _trip.headsign, 
            _trip.short_name, 
            _trip.direction_type AS direction, 
            _trip.block_id, 
            _trip.shape_id, 
            _trip.accessibility_type_data AS accessibility_type, 
            _trip.internal_id, 
            _trip.last_updated, 
            _trip.import_id
        FROM UNNEST(_trips) AS _trip
    ) AS source
    ON target.id = source.id AND target.data_origin = source.data_origin
    WHEN MATCHED THEN
        UPDATE SET
            -- Only update fields that need to change
            route_id = source.route_id,
            service_id = source.service_id,
            headsign = source.headsign,
            short_name = source.short_name,
            direction = source.direction,
            block_id = source.block_id,
            shape_id = source.shape_id,
            accessibility_type = source.accessibility_type,
            internal_id = source.internal_id,
            last_updated = source.last_updated,
            import_id = source.import_id
    WHEN NOT MATCHED THEN
        INSERT (
            data_origin, id, route_id, service_id, headsign, short_name, direction, block_id, shape_id, accessibility_type, internal_id, last_updated, import_id
        )
        VALUES (
            source.data_origin, 
            source.id, 
            source.route_id, 
            source.service_id, 
            source.headsign, 
            source.short_name, 
            source.direction, 
            source.block_id, 
            source.shape_id, 
            source.accessibility_type, 
            source.internal_id, 
            source.last_updated, 
            source.import_id
        );
END;
$$;
