DROP PROCEDURE IF EXISTS public.upsert_shapes;

CREATE OR REPLACE PROCEDURE public.upsert_shapes(
    _shapes public.shapes_type[]
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.shapes (
        internal_id, data_origin, id, sequence, latitude, longitude, geo_location, distance_travelled, last_updated, import_id
    )
    SELECT DISTINCT 
        _shape.internal_id, 
        _shape.data_origin, 
        _shape.id, 
        _shape.sequence_data, 
        _shape.latitude, 
        _shape.longitude, 
        ST_SetSRID(ST_MakePoint(_shape.longitude, _shape.latitude), 4326), 
        _shape.distance_travelled, 
        _shape.last_updated, 
        _shape.import_id
    FROM UNNEST(_shapes) AS _shape
    ON CONFLICT (id, data_origin, sequence) DO UPDATE
    SET
        -- Only update fields if they differ from the existing ones
        data_origin = EXCLUDED.data_origin,
        latitude = EXCLUDED.latitude,
        longitude = EXCLUDED.longitude,
        distance_travelled = EXCLUDED.distance_travelled,
        last_updated = EXCLUDED.last_updated,
        import_id = EXCLUDED.import_id,
        -- Check and update geo_location only if the value has changed
        geo_location = ST_SetSRID(ST_MakePoint(EXCLUDED.longitude, EXCLUDED.latitude), 4326);
END;
$$;
