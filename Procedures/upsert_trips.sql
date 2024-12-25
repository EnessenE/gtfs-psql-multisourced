CREATE OR REPLACE PROCEDURE public.upsert_trips(
    trips public.trips_type
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.trips(
        data_origin, id, route_id, service_id, headsign, short_name, direction, block_id, shape_id, accessibility_type, internal_id, last_updated, import_id
    )
    SELECT data_origin, id, route_id, service_id, headsign, short_name, direction, block_id, shape_id, accessibility_type, internal_id, last_updated, import_id
    FROM trips
    ON CONFLICT(id, data_origin) DO UPDATE
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