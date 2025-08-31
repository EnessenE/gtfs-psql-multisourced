CREATE OR REPLACE PROCEDURE public.merge_stop(IN p_target_stop_id text, IN p_supplier_data_origin text)
LANGUAGE plpgsql
AS $BODY$
DECLARE
    -- Target stop details
    v_target_internal_id    uuid;
    v_target_geo            geography;
    v_target_name           text;
    v_target_parent_station text;
    v_target_stop_type      integer;
    v_target_data_origin    character varying(100);

    -- Grouping and thresholds
    v_surviving_group_id    uuid;
    v_distance_strict       float;
    v_distance_loose        float;
    v_name_similarity_threshold float := 0.2;

    -- Array to hold all existing group IDs found
    v_existing_group_ids    uuid[];

BEGIN
    -- Temp table for initial candidates found based on the target stop
    CREATE TEMP TABLE temp_candidate_stops (
        internal_id uuid,
        data_origin character varying(100),
        PRIMARY KEY (internal_id, data_origin)
    ) ON COMMIT DROP;

    -- Temp table for the final, deduplicated list of ALL stops to be grouped
    CREATE TEMP TABLE temp_final_group_members (
        related_stop uuid,
        related_data_origin character varying(100),
        PRIMARY KEY (related_stop, related_data_origin)
    ) ON COMMIT DROP;

    -- Pre-processing: Attempt to determine the stop_type from route data
    UPDATE stops
    SET stop_type = COALESCE((
        SELECT r.type
        FROM stop_times st
        JOIN trips t ON st.trip_id = t.id AND st.data_origin = t.data_origin
        JOIN routes r ON t.route_id = r.id AND t.data_origin = r.data_origin
        WHERE st.stop_id = p_target_stop_id
        AND st.data_origin = p_supplier_data_origin
        LIMIT 1), 1000)
    WHERE data_origin = p_supplier_data_origin AND id = p_target_stop_id;

    -- 1. Retrieve the target stop's information
    SELECT s.internal_id, geography(s.geo_location), s.name, s.parent_station, s.stop_type, s.data_origin
    INTO v_target_internal_id, v_target_geo, v_target_name, v_target_parent_station, v_target_stop_type, v_target_data_origin
    FROM public.stops s
    WHERE s.id = p_target_stop_id AND s.data_origin = p_supplier_data_origin;

    IF NOT FOUND THEN
        RAISE NOTICE 'Target stop (id: %, data_origin: %) not found. Skipping.', p_target_stop_id, p_supplier_data_origin;
        RETURN;
    END IF;

    -- 2. Check if the target stop is already grouped.
    IF EXISTS (
         SELECT 1 FROM public.related_stops rs
         WHERE rs.related_stop = v_target_internal_id AND rs.related_data_origin = v_target_data_origin
    ) THEN
         RAISE NOTICE 'Target stop (internal_id: %, data_origin: %) is already in a group. Skipping.', v_target_internal_id, v_target_data_origin;
         RETURN;
    END IF;

    -- 3. Determine distance thresholds
    CASE v_target_stop_type
        WHEN 0 THEN v_distance_strict := 50.0;  v_distance_loose  := 200.0;
        WHEN 1 THEN v_distance_strict := 75.0;  v_distance_loose  := 300.0;
        ELSE        v_distance_strict := 75.0;  v_distance_loose  := 300.0;
    END CASE;

    -- 4. Find all potential candidates and insert them into the temporary table.
    INSERT INTO temp_candidate_stops(internal_id, data_origin)
    SELECT s.internal_id, s.data_origin
    FROM public.stops s
    WHERE
        (s.data_origin = v_target_data_origin AND (
            (NULLIF(v_target_parent_station, '') IS NOT NULL AND s.parent_station = v_target_parent_station) OR
            (NULLIF(v_target_parent_station, '') IS NOT NULL AND s.id = v_target_parent_station) OR
            (NULLIF(s.parent_station, '') IS NOT NULL AND s.parent_station = p_target_stop_id)
        )) OR
        (s.stop_type = v_target_stop_type AND (
            ST_DWithin(geography(s.geo_location), v_target_geo, v_distance_strict) OR
            (ST_DWithin(geography(s.geo_location), v_target_geo, v_distance_loose) AND SIMILARITY(s.name, v_target_name) >= v_name_similarity_threshold)
        ))
    ON CONFLICT (internal_id, data_origin) DO NOTHING;

    -- Always include the target stop itself.
    INSERT INTO temp_candidate_stops(internal_id, data_origin)
    VALUES (v_target_internal_id, v_target_data_origin)
    ON CONFLICT (internal_id, data_origin) DO NOTHING;

    -- 5. Find ALL existing groups connected to ANY of our candidate stops.
    SELECT array_agg(DISTINCT rs.primary_stop)
    INTO v_existing_group_ids
    FROM public.related_stops rs
    JOIN temp_candidate_stops t ON rs.related_stop = t.internal_id AND rs.related_data_origin = t.data_origin;

    -- 6. Determine the final group ID.
    IF v_existing_group_ids IS NULL OR array_length(v_existing_group_ids, 1) = 0 THEN
        v_surviving_group_id := uuid_generate_v4();
        RAISE NOTICE 'No existing groups found for candidates. Creating new group ID: %', v_surviving_group_id;

        -- For a new group, the final members are just the candidates.
        INSERT INTO temp_final_group_members(related_stop, related_data_origin)
        SELECT internal_id, data_origin FROM temp_candidate_stops
        ON CONFLICT (related_stop, related_data_origin) DO NOTHING;
    ELSE
        v_surviving_group_id := v_existing_group_ids[1];
        RAISE NOTICE 'Found existing group(s): %. Merging all into surviving group ID: %', v_existing_group_ids, v_surviving_group_id;

        -- ****** START: THE ROBUST FIX ******

        -- Step 1: Gather ALL unique stops from ALL groups to be merged.
        INSERT INTO temp_final_group_members(related_stop, related_data_origin)
        SELECT rs.related_stop, rs.related_data_origin
        FROM public.related_stops rs
        WHERE rs.primary_stop = ANY(v_existing_group_ids)
        ON CONFLICT (related_stop, related_data_origin) DO NOTHING;

        -- Step 2: Add all the new candidate stops to this master list.
        -- ON CONFLICT handles deduplication against existing group members.
        INSERT INTO temp_final_group_members(related_stop, related_data_origin)
        SELECT tcs.internal_id, tcs.data_origin
        FROM temp_candidate_stops tcs
        ON CONFLICT (related_stop, related_data_origin) DO NOTHING;

        -- Step 3: Delete all old versions of the groups being merged. This cleans the slate.
        DELETE FROM public.related_stops
        WHERE primary_stop = ANY(v_existing_group_ids);

        -- ****** END: THE ROBUST FIX ******
    END IF;

    -- 7. Insert the final, consolidated group into the table.
    -- This is now guaranteed to be free of duplicates.
    INSERT INTO public.related_stops(primary_stop, related_stop, related_data_origin)
    SELECT v_surviving_group_id, tfgm.related_stop, tfgm.related_data_origin
    FROM temp_final_group_members tfgm;

    RAISE NOTICE 'Merge process for target stop (id: %, data_origin: %) completed. Group ID: %.', p_target_stop_id, p_supplier_data_origin, v_surviving_group_id;

END;
$BODY$;