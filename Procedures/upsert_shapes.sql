-- PROCEDURE: public.upsert_shapes(shapes_type[])

-- DROP PROCEDURE IF EXISTS public.upsert_shapes(shapes_type[]);

CREATE OR REPLACE PROCEDURE public.upsert_shapes(
    IN _shapes public.shapes_type[]
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Perform a single bulk insert for all rows in the _shapes array
    INSERT INTO public.shapes (
        internal_id, data_origin, id, sequence, latitude, longitude, geo_location, distance_travelled, last_updated, import_id
    )
    SELECT 
        _shape.internal_id, 
        _shape.data_origin, 
        _shape.id, 
        _shape.sequence_data,  -- Use _sequence_data from the array
        _shape.latitude, 
        _shape.longitude, 
        ST_SetSRID(ST_MakePoint(_shape.longitude, _shape.latitude), 4326),  -- Create geo_location point
        _shape.distance_travelled, 
        _shape.last_updated, 
        _shape.import_id
    FROM UNNEST(_shapes) AS _shape
    ON CONFLICT (data_origin, id, sequence, import_id) 
    DO NOTHING;  -- Ignore the conflict, effectively skipping duplicate entries
END;
$$;

ALTER PROCEDURE public.bulk_insert_shapes(shapes_type[])
    OWNER TO postgres;
