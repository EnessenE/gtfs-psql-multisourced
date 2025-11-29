-- Ensure necessary extensions are available in your database:
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- CREATE EXTENSION IF NOT EXISTS pg_trgm;
-- CREATE EXTENSION IF NOT EXISTS postgis;

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
    v_chosen_guid           uuid;
    v_distance_strict       float;
    v_distance_loose        float;
    v_name_similarity_threshold float := 0.2;

BEGIN
    -- Use a temporary table to hold all stops that should be grouped together.
    -- This solves the CTE scope issue, as the temp table is visible throughout the procedure.
    -- ON COMMIT DROP ensures it is cleaned up automatically when the transaction completes.
    CREATE TEMP TABLE temp_stops_to_group (
        related_stop uuid,
        related_data_origin character varying(100),
        PRIMARY KEY (related_stop, related_data_origin)
    ) ON COMMIT DROP;

    update stops
    set stop_type = COALESCE((
        SELECT r.type
        FROM stop_times2 st
        JOIN trips t ON st.trip_id = t.id AND st.data_origin = t.data_origin
        JOIN routes r ON t.route_id = r.id AND t.data_origin = r.data_origin
        WHERE st.stop_id = p_target_stop_id
        AND st.data_origin = p_supplier_data_origin
    where data_origin = p_supplier_data_origin and id = p_target_stop_id;

    RAISE NOTICE 'Route type detection for target stop (id: %, data_origin: %) completed for group ID: %.', p_target_stop_id, p_supplier_data_origin, v_chosen_guid;

    -- 1. Retrieve the target stop's information
    SELECT
        s.internal_id, geography(s.geo_location), s.name, s.parent_station, s.stop_type, s.data_origin
    INTO
        v_target_internal_id, v_target_geo, v_target_name, v_target_parent_station, v_target_stop_type, v_target_data_origin
    FROM public.stops s
    WHERE s.id = p_target_stop_id AND s.data_origin = p_supplier_data_origin;

    IF NOT FOUND THEN
        RAISE NOTICE 'Target stop (id: %, data_origin: %) not found. Skipping.', p_target_stop_id, p_supplier_data_origin;
        RETURN;
    END IF;

    -- 2. Check if the target stop is already part of a group.
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
    INSERT INTO temp_stops_to_group(related_stop, related_data_origin)
    SELECT s.internal_id, s.data_origin
    FROM public.stops s
    WHERE s.internal_id != v_target_internal_id
      AND (
            -- Condition 1: GTFS hierarchy
            (s.data_origin = v_target_data_origin AND (
                (v_target_parent_station IS NOT NULL AND v_target_parent_station <> '' AND s.parent_station = v_target_parent_station) OR
                (v_target_parent_station IS NOT NULL AND v_target_parent_station <> '' AND s.id = v_target_parent_station) OR
                (s.parent_station IS NOT NULL AND s.parent_station <> '' AND s.parent_station = p_target_stop_id)
            )) OR
            -- Condition 2: Name and position
            (s.stop_type = v_target_stop_type AND (
                ST_DWithin(geography(s.geo_location), v_target_geo, v_distance_strict) OR
                (ST_DWithin(geography(s.geo_location), v_target_geo, v_distance_loose) AND SIMILARITY(s.name, v_target_name) >= v_name_similarity_threshold)
            ))
        );

    -- Always add the target stop itself to the list of stops to be grouped.
    INSERT INTO temp_stops_to_group(related_stop, related_data_origin)
    VALUES (v_target_internal_id, v_target_data_origin)
    ON CONFLICT (related_stop, related_data_origin) DO NOTHING;

    -- 5. Determine the Group ID: find an existing one from any stop in our temp table, or create a new one.
    SELECT rs.primary_stop
    INTO v_chosen_guid
    FROM public.related_stops rs
    JOIN temp_stops_to_group t ON rs.related_stop = t.related_stop AND rs.related_data_origin = t.related_data_origin
    LIMIT 1; -- Found an existing group one of the stops belongs to. Use it.

    IF v_chosen_guid IS NULL THEN
        v_chosen_guid := uuid_generate_v4();
        RAISE NOTICE 'No existing group found. Creating new group with ID: %', v_chosen_guid;
    ELSE
        RAISE NOTICE 'Found existing group: %. Merging stops into this group.', v_chosen_guid;
    END IF;

    -- 6. Insert all stops from the temp table into the determined group.
    -- ON CONFLICT is crucial for merging, preventing errors if a stop is already in the chosen group.
    INSERT INTO public.related_stops(primary_stop, related_stop, related_data_origin)
    SELECT v_chosen_guid, t.related_stop, t.related_data_origin
    FROM temp_stops_to_group t
    ON CONFLICT (primary_stop, related_stop, related_data_origin) DO NOTHING;

    RAISE NOTICE 'Merge process for target stop (id: %, data_origin: %) completed for group ID: %.', p_target_stop_id, p_supplier_data_origin, v_chosen_guid;


    -- The temporary table is automatically dropped here because of ON COMMIT DROP.
END;
$BODY$;