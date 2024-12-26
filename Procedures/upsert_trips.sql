DROP PROCEDURE IF EXISTS public.upsert_trips;

CREATE OR REPLACE PROCEDURE public.upsert_trips(
    _trips public.trips_type[]
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.trips(
        data_origin, id, route_id, service_id, headsign, short_name, direction, block_id, shape_id, accessibility_type, internal_id, last_updated, import_id
    )
    SELECT 
        _trip.data_origin, 
        _trip.id, 
        _trip.route_id, 
        _trip.service_id, 
        _trip.headsign, 
        _trip.short_name, 
        _trip.direction_type, 
        _trip.block_id, 
        _trip.shape_id, 
        _trip.accessibility_type_data, 
        _trip.internal_id, 
        _trip.last_updated, 
        _trip.import_id
    FROM UNNEST(_trips) AS _trip
    ON CONFLICT (id, data_origin) DO UPDATE
    SET 
        data_origin = EXCLUDED.data_origin,
        route_id = EXCLUDED.route_id,
        service_id = EXCLUDED.service_id,
        headsign = EXCLUDED.headsign,
        short_name = EXCLUDED.short_name,
        direction = EXCLUDED.direction,
        block_id = EXCLUDED.block_id,
        shape_id = EXCLUDED.shape_id,
        accessibility_type = EXCLUDED.accessibility_type,
        internal_id = EXCLUDED.internal_id,
        last_updated = EXCLUDED.last_updated,
        import_id = EXCLUDED.import_id;
END;
$$;
