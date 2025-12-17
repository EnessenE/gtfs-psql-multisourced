-- PROCEDURE: public.merge_stop(text, text)

-- DROP PROCEDURE IF EXISTS public.merge_stop(text, text);

CREATE OR REPLACE PROCEDURE public.merge_stop(
	IN p_target_stop_id text,
	IN p_supplier_data_origin text)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    -- Target stop details
    v_target_internal_id    bigint;
    v_target_geo            geography;
    v_target_name           text;
    v_target_parent_station text;
    v_target_stop_type      integer;
    v_target_data_origin    character varying(100);

    -- Grouping and thresholds
    v_chosen_guid           uuid;
    v_distance_strict       float := 75;
    v_distance_loose        float := 250;
    v_name_similarity_threshold float := 0.6;

BEGIN
    -- Create a temporary table for candidate stops.
    CREATE TEMP TABLE temp_stops_to_group (
        related_stop bigint,
        related_data_origin character varying(100),
        PRIMARY KEY (related_stop, related_data_origin)
    ) ON COMMIT DROP;

    -- 1. Find the target stop's details.
    SELECT
        s.internal_id, geography(s.geo_location), s.name, s.parent_station, s.stop_type, s.data_origin
    INTO
        v_target_internal_id, v_target_geo, v_target_name, v_target_parent_station, v_target_stop_type, v_target_data_origin
    FROM public.stops s
    WHERE s.id = p_target_stop_id AND s.data_origin = p_supplier_data_origin;

    -- FIX: Gracefully exit if the target stop ID does not exist.
    IF NOT FOUND THEN
        RAISE NOTICE 'Target stop (id: %, data_origin: %) not found. Skipping.', p_target_stop_id, p_supplier_data_origin;
        RETURN;
    END IF;

    -- 2. Set stop type based on the routes it serves. This query is indexed and should be fast.
    UPDATE stops
    SET stop_type = COALESCE((
        SELECT r.type
        FROM stop_times st
        JOIN trips t ON st.trip_id = t.id AND st.data_origin = t.data_origin
        JOIN routes r ON t.route_id = r.id AND t.data_origin = r.data_origin
        WHERE st.stop_id = p_target_stop_id
        AND st.data_origin = p_supplier_data_origin
        LIMIT 1), NULL)
    WHERE data_origin = p_supplier_data_origin AND id = p_target_stop_id;

    -- 3. Check if the target stop is already part of a group.
    IF EXISTS (
         SELECT 1 FROM public.related_stops rs
         WHERE rs.related_stop = v_target_internal_id
    ) THEN
         RAISE NOTICE 'Target stop (internal_id: %, data_origin: %) is already in a group. Skipping.', v_target_internal_id, v_target_data_origin;
         RETURN;
    END IF;

    -- 4. PERFORMANCE OPTIMIZATION: Broad Phase - Find all potential candidates.
    -- This query is fast because it uses GIST indexes for geography and name similarity.
    INSERT INTO temp_stops_to_group(related_stop, related_data_origin)
    SELECT s.internal_id, s.data_origin
    FROM public.stops s
    WHERE s.internal_id != v_target_internal_id
      AND (
            -- Condition 1: GTFS hierarchy (parent station logic)
            (s.data_origin = v_target_data_origin AND (
                (v_target_parent_station IS NOT NULL AND v_target_parent_station <> '' AND s.parent_station = v_target_parent_station) OR
                (v_target_parent_station IS NOT NULL AND v_target_parent_station <> '' AND s.id = v_target_parent_station) OR
                (s.parent_station IS NOT NULL AND s.parent_station <> '' AND s.parent_station = p_target_stop_id)
            )) OR
            -- Condition 2: Name and position (with more restrictive logic)
            (s.stop_type = v_target_stop_type AND
                (ST_DWithin(geography(s.geo_location), v_target_geo, v_distance_strict) OR
                 (ST_DWithin(geography(s.geo_location), v_target_geo, v_distance_loose) AND SIMILARITY(s.name, v_target_name) >= v_name_similarity_threshold)
                )
            )
        );

    -- 5. PERFORMANCE OPTIMIZATION: Narrow Phase - Remove subsequent stops.
    -- This single, set-based DELETE is far more efficient than a row-by-row check.
    DELETE FROM temp_stops_to_group t
    USING stop_times st1, stop_times st2, stops s
    WHERE t.related_stop = s.internal_id AND t.related_data_origin = s.data_origin -- Join temp table to stops
      AND st2.stop_id = s.id AND st2.data_origin = s.data_origin -- Join stops to their stop_times
      AND st1.trip_id = st2.trip_id AND st1.data_origin = st2.data_origin -- Find common trips
      AND st1.stop_id = p_target_stop_id AND st1.data_origin = p_supplier_data_origin -- Filter to trips serving the target stop
      AND st1.stop_sequence != st2.stop_sequence; -- Ensure they are different stops on the same trip

    -- 6. Always add the target stop itself to the final group.
    INSERT INTO temp_stops_to_group(related_stop, related_data_origin)
    VALUES (v_target_internal_id, v_target_data_origin)
    ON CONFLICT (related_stop, related_data_origin) DO NOTHING;

    -- 7. Determine the Group ID.
    v_chosen_guid := uuid_generate_v4();

    -- 8. Insert all valid stops into the group.
    INSERT INTO public.related_stops(primary_stop, related_stop, related_data_origin)
    SELECT v_chosen_guid, t.related_stop, t.related_data_origin
    FROM temp_stops_to_group t
    ON CONFLICT (primary_stop, related_stop, related_data_origin) DO NOTHING;

    RAISE NOTICE 'Merge process for target stop (id: %, data_origin: %) completed for group ID: %.', p_target_stop_id, p_supplier_data_origin, v_chosen_guid;

END;
$BODY$;
ALTER PROCEDURE public.merge_stop(text, text)
    OWNER TO postgres;

