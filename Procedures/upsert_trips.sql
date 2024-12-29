-- PROCEDURE: public.upsert_trips(trips_type[])

-- DROP PROCEDURE IF EXISTS public.upsert_trips(trips_type[]);

CREATE OR REPLACE PROCEDURE public.upsert_trips(
    IN _trips public.trips_type[]
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Perform a single bulk insert for all rows in the _trips array
    INSERT INTO public.trips (
        data_origin, id, route_id, service_id, headsign, short_name, direction, block_id, shape_id, accessibility_type, internal_id, last_updated, import_id
    )
    SELECT DISTINCT
        _trip.data_origin, 
        _trip.id, 
        _trip.route_id, 
        _trip.service_id, 
        _trip.headsign, 
        _trip.short_name, 
        _trip.direction_type,  -- Use _direction_type from the array (mapped to 'direction')
        _trip.block_id, 
        _trip.shape_id, 
        _trip.accessibility_type_data,  -- Use _accessibility_type_data from the array
        _trip.internal_id, 
        _trip.last_updated, 
        _trip.import_id
    FROM UNNEST(_trips) AS _trip
    ON CONFLICT (data_origin, id, import_id)
    DO NOTHING;  -- Ignore the conflict, effectively skipping duplicate entries
END;
$$;

ALTER PROCEDURE public.upsert_trips(trips_type[])
    OWNER TO postgres;
