-- PROCEDURE: public.upsert_stop_times2(stop_times_type[])

-- DROP PROCEDURE IF EXISTS public.upsert_stop_times2(stop_times_type[]);

CREATE OR REPLACE PROCEDURE public.upsert_stop_times2(
	IN _stop_times stop_times_type[])
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    -- Use a simpler approach without temp tables that might be causing issues
    -- Insert directly with ON CONFLICT handling for upsert behavior

    -- Bulk insert data into the temporary table (much faster than row-by-row)
    -- Direct insertion with ON CONFLICT handling
    INSERT INTO public.stop_times2 (
        data_origin, trip_id, stop_id, stop_sequence, arrival_time, departure_time, days_since_start_arrival, days_since_start_departure, stop_headsign,
        pickup_type, drop_off_type, shape_dist_travelled, timepoint_type, internal_id, last_updated, import_id
    )
    SELECT
        _stop_time.data_origin, 
        _stop_time.trip_id, 
        _stop_time.stop_id, 
        _stop_time.stop_sequence_data,
        _stop_time.arrival_time_data, 
        _stop_time.departure_time_data, 
        _stop_time.days_since_start_arrival, 
        _stop_time.days_since_start_departure, 
        _stop_time.stop_headsign, 
        _stop_time.pickup_type_data,
        _stop_time.drop_off_type_data,
        _stop_time.shape_dist_travelled, 
        _stop_time.timepoint_type_data,
        _stop_time.internal_id, 
        _stop_time.last_updated, 
        COALESCE(_stop_time.import_id, '00000000-0000-0000-0000-000000000000'::uuid)
    FROM UNNEST(_stop_times) AS _stop_time
    ON CONFLICT (data_origin, trip_id, stop_id, stop_sequence, import_id) 
    DO UPDATE SET
        arrival_time = EXCLUDED.arrival_time,
        departure_time = EXCLUDED.departure_time,
        days_since_start_arrival = EXCLUDED.days_since_start_arrival,
        days_since_start_departure = EXCLUDED.days_since_start_departure,
        stop_headsign = EXCLUDED.stop_headsign,
        pickup_type = EXCLUDED.pickup_type,
        drop_off_type = EXCLUDED.drop_off_type,
        shape_dist_travelled = EXCLUDED.shape_dist_travelled,
        timepoint_type = EXCLUDED.timepoint_type,
        internal_id = EXCLUDED.internal_id,
        last_updated = EXCLUDED.last_updated;
END;
$BODY$;
ALTER PROCEDURE public.upsert_stop_times2(stop_times_type[])
    OWNER TO postgres;



-- PROCEDURE: public.upsert_stop_times2(stop_times_type[])

-- DROP PROCEDURE IF EXISTS public.upsert_stop_times2(stop_times_type[]);

CREATE OR REPLACE PROCEDURE public.upsert_stop_times2(
	IN _stop_times stop_times_type[])
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    -- Create a temporary table (preferably UNLOGGED if your PG version supports it in procedures,
    -- otherwise, a regular TEMP TABLE is still often better than direct UNNEST for large arrays)
    -- Explicitly define columns to match your stop_times_type structure for clarity
    CREATE TEMP TABLE temp_stop_times_batch (
        data_origin character varying(100),
        trip_id text,
        stop_id text,
        stop_sequence_data bigint,
        arrival_time time without time zone,
        departure_time time without time zone,
        stop_headsign text,
        pickup_type_data integer,
        drop_off_type_data integer,
        shape_dist_travelled double precision,
        timepoint_type_data integer,
        internal_id uuid,
        last_updated timestamp with time zone,
        import_id uuid
    ) ON COMMIT DROP; -- Cleans up automatically

    -- Insert data from the array into the temp table
    INSERT INTO temp_stop_times_batch
    SELECT
        s.data_origin,
        s.trip_id,
        s.stop_id,
        s.stop_sequence_data,
        s.arrival_time,
        s.departure_time,
        s.stop_headsign,
        s.pickup_type_data,
        s.drop_off_type_data,
        s.shape_dist_travelled,
        s.timepoint_type_data,
        s.internal_id,
        s.last_updated,
        COALESCE(s.import_id, '00000000-0000-0000-0000-000000000000'::uuid)
    FROM UNNEST(_stop_times) AS s;

    -- Now, upsert from the temp table into the main partitioned table
    INSERT INTO public.stop_times2 (
        data_origin, trip_id, stop_id, stop_sequence, arrival_time, departure_time, stop_headsign,
        pickup_type, drop_off_type, shape_dist_travelled, timepoint_type, internal_id, last_updated, import_id
    )
    SELECT
        b.data_origin,
        b.trip_id,
        b.stop_id,
        b.stop_sequence_data, -- map to stop_sequence in table
        b.arrival_time,
        b.departure_time,
        b.stop_headsign,
        b.pickup_type_data,   -- map to pickup_type in table
        b.drop_off_type_data, -- map to drop_off_type in table
        b.shape_dist_travelled,
        b.timepoint_type_data, -- map to timepoint_type in table
        b.internal_id,
        b.last_updated,
        b.import_id
    FROM temp_stop_times_batch b
    ON CONFLICT (data_origin, trip_id, stop_id, stop_sequence, import_id)
    DO UPDATE SET
        arrival_time = EXCLUDED.arrival_time,
        departure_time = EXCLUDED.departure_time,
        stop_headsign = EXCLUDED.stop_headsign,
        pickup_type = EXCLUDED.pickup_type,
        drop_off_type = EXCLUDED.drop_off_type,
        shape_dist_travelled = EXCLUDED.shape_dist_travelled,
        timepoint_type = EXCLUDED.timepoint_type,
        internal_id = EXCLUDED.internal_id,
        last_updated = EXCLUDED.last_updated;

    -- temp_stop_times_batch is dropped automatically due to ON COMMIT DROP
END;
$BODY$;
ALTER PROCEDURE public.upsert_stop_times2(stop_times_type[])
    OWNER TO postgres;
