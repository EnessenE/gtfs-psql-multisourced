-- Ensure necessary extensions are available in your database:
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp"; -- For uuid_generate_v4()
-- CREATE EXTENSION IF NOT EXISTS pg_trgm;   -- For SIMILARITY()
-- CREATE EXTENSION IF NOT EXISTS postgis;   -- For ST_DWithin, geography(), etc.

-- Note: The public.related_stops table DDL must include a unique constraint like:
-- UNIQUE (primary_stop, related_stop, related_data_origin)
-- The column `related_data_origin` must also exist.

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
    -- 1. Retrieve the target stop's information
    SELECT
        s.internal_id,
        geography(s.geo_location),
        s.name,
        s.parent_station,
        s.stop_type,
        s.data_origin
    INTO
        v_target_internal_id,
        v_target_geo,
        v_target_name,
        v_target_parent_station,
        v_target_stop_type,
        v_target_data_origin
    FROM public.stops s
    WHERE s.id = p_target_stop_id AND s.data_origin = p_supplier_data_origin;

    IF NOT FOUND THEN
        RAISE NOTICE 'Target stop (id: %, data_origin: %) not found. Skipping.', p_target_stop_id, p_supplier_data_origin;
        RETURN;
    END IF;

    -- 2. Check if the target stop is already part of a group. If so, there's nothing to do.
    IF EXISTS (
         SELECT 1
         FROM public.related_stops rs
         WHERE rs.related_stop = v_target_internal_id
           AND rs.related_data_origin = v_target_data_origin
    ) THEN
         RAISE NOTICE 'Target stop (internal_id: %, data_origin: %) is already in a group. Skipping.', v_target_internal_id, v_target_data_origin;
         RETURN;
    END IF;

    -- 3. Determine distance thresholds based on the target stop's type
    CASE v_target_stop_type
        WHEN 0 THEN -- Platform
            v_distance_strict := 50.0;
            v_distance_loose  := 200.0;
        WHEN 1 THEN -- Station
            v_distance_strict := 75.0;
            v_distance_loose  := 300.0;
        ELSE        -- Default
            v_distance_strict := 75.0;
            v_distance_loose  := 300.0;
    END CASE;

    -- 4. Find all potential candidates for merging.
    -- This CTE gathers all stops that *could* be related to our target.
    WITH potential_candidates AS (
        SELECT
            s.internal_id AS candidate_internal_id,
            s.data_origin AS candidate_data_origin
        FROM public.stops s
        WHERE s.internal_id != v_target_internal_id -- Exclude the target stop itself for now
          AND (
                -- Condition 1: GTFS hierarchy linking (parent/child/sibling)
                (
                    s.data_origin = v_target_data_origin
                    AND (
                        (v_target_parent_station IS NOT NULL AND v_target_parent_station <> '' AND s.parent_station = v_target_parent_station) OR -- Siblings
                        (v_target_parent_station IS NOT NULL AND v_target_parent_station <> '' AND s.id = v_target_parent_station) OR -- Candidate is parent
                        (s.parent_station IS NOT NULL AND s.parent_station <> '' AND s.parent_station = p_target_stop_id) -- Candidate is child
                    )
                )
                OR
                -- Condition 2: Name and position check
                (
                    s.stop_type = v_target_stop_type
                    AND (
                        ST_DWithin(geography(s.geo_location), v_target_geo, v_distance_strict) OR
                        (
                            ST_DWithin(geography(s.geo_location), v_target_geo, v_distance_loose) AND
                            SIMILARITY(s.name, v_target_name) >= v_name_similarity_threshold
                        )
                    )
                )
            )
    ),
    -- This CTE includes the target stop along with any found candidates
    all_stops_to_group AS (
        SELECT candidate_internal_id, candidate_data_origin FROM potential_candidates
        UNION
        -- Always include the target stop itself in the list of stops to group
        SELECT v_target_internal_id, v_target_data_origin
    )
    -- 5. Determine the Group ID: either find an existing one or create a new one.
    SELECT rs.primary_stop
    INTO v_chosen_guid
    FROM public.related_stops rs
    JOIN all_stops_to_group g ON rs.related_stop = g.candidate_internal_id AND rs.related_data_origin = g.candidate_data_origin
    LIMIT 1; -- Found an existing group one of the stops belongs to. Use it.

    -- If no existing group was found among any of the stops, generate a new UUID.
    IF v_chosen_guid IS NULL THEN
        v_chosen_guid := uuid_generate_v4();
        RAISE NOTICE 'No existing group found. Creating new group with ID: %', v_chosen_guid;
    ELSE
        RAISE NOTICE 'Found existing group: %. Merging stops into this group.', v_chosen_guid;
    END IF;

    -- 6. Insert all stops (target + candidates) into the determined group.
    -- The ON CONFLICT clause is crucial. It prevents errors if a stop is already
    -- in the chosen group (in a merge scenario) and handles the user's original problem
    -- by ensuring at least the target stop is inserted into a new group if no candidates are found.
    WITH all_stops_to_group AS (
        SELECT candidate_internal_id, candidate_data_origin FROM potential_candidates
        UNION
        SELECT v_target_internal_id, v_target_data_origin
    )
    INSERT INTO public.related_stops(primary_stop, related_stop, related_data_origin)
    SELECT v_chosen_guid, s.candidate_internal_id, s.candidate_data_origin
    FROM all_stops_to_group s
    ON CONFLICT (primary_stop, related_stop, related_data_origin) DO NOTHING;

    RAISE NOTICE 'Merge process for target stop (id: %, data_origin: %) completed for group ID: %.', p_target_stop_id, p_supplier_data_origin, v_chosen_guid;

END;
$BODY$;