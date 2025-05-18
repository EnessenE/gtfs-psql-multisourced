-- Ensure necessary extensions are available in your database:
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp"; -- For uuid_generate_v4()
-- CREATE EXTENSION IF NOT EXISTS pg_trgm;   -- For SIMILARITY()
-- CREATE EXTENSION IF NOT EXISTS postgis;   -- For ST_DWithin, geography(), etc.

-- Note: The public.related_stops table DDL must be corrected to include 'related_data_origin' as a column
-- as shown in the documentation above.

CREATE OR REPLACE PROCEDURE public.merge_stop(IN p_target_stop_id text, IN p_supplier_data_origin text)
LANGUAGE plpgsql
AS $BODY$
DECLARE
    r_target_stop_details record; -- To hold target stop fields (original id, etc.)

    v_chosen_guid uuid;
    v_target_internal_id uuid;
    v_target_geo geography;
    v_target_name text;
    v_target_parent_station text;
    v_target_stop_type integer;
    v_target_data_origin character varying(100);

    -- Distance thresholds (customize these values based on your specific stop_types and needs)
    v_distance_strict float;
    v_distance_loose float;
    v_name_similarity_threshold float := 0.2; -- Default from original query, can be adjusted

BEGIN
    -- Retrieve the target stop information
    SELECT
        s.internal_id,
        geography(s.geo_location), -- Cast to geography for accurate distance calculations
        s.name,
        s.parent_station,
        s.stop_type,
        s.data_origin,
        s.id -- Keep the original string ID for parent_station checks where s.parent_station = target.id
    INTO
        v_target_internal_id,
        v_target_geo,
        v_target_name,
        v_target_parent_station,
        v_target_stop_type,
        v_target_data_origin,
        r_target_stop_details -- Captures the whole selected row, useful for s.id
    FROM public.stops s
    WHERE s.id = p_target_stop_id
      AND s.data_origin = p_supplier_data_origin;

    IF NOT FOUND THEN
        RAISE NOTICE 'Target stop (id: %, data_origin: %) not found.', p_target_stop_id, p_supplier_data_origin;
        RETURN;
    END IF;

    -- Check if the target stop is already part of any merged group.
    -- A stop is identified by (internal_id, data_origin) in the context of related_stops.
    IF EXISTS (
         SELECT 1
         FROM public.related_stops rs
         WHERE rs.related_stop = v_target_internal_id
           AND rs.related_data_origin = v_target_data_origin
    ) THEN
         RAISE NOTICE 'Target stop (internal_id: %, data_origin: %) is already related to a group. Skipping.', v_target_internal_id, v_target_data_origin;
         RETURN;
    END IF;

    -- Generate a new GUID for this merge group operation
    v_chosen_guid := uuid_generate_v4();

    -- Determine distance thresholds based on the target stop's type.
    -- !!! USER CUSTOMIZATION REQUIRED HERE !!!
    -- Adjust stop_type values and corresponding distances as per your GTFS data and business rules.
    CASE v_target_stop_type
        WHEN 0 THEN -- Example: Platform or similar small stop point
            v_distance_strict := 50.0;  -- 50 meters for strict proximity match
            v_distance_loose  := 200.0; -- 200 meters for looser proximity + name match
        WHEN 1 THEN -- Example: Station or larger interchange area
            v_distance_strict := 75.0;  -- 75 meters
            v_distance_loose  := 300.0; -- 300 meters
        -- Add more WHEN clauses for other stop_types if needed
        ELSE        -- Default for any other stop_types
            v_distance_strict := 75.0;
            v_distance_loose  := 300.0;
    END CASE;

    -- Find candidate stops for merging
    WITH candidates AS (
        SELECT
            s.internal_id AS candidate_internal_id,
            s.data_origin AS candidate_data_origin
        FROM public.stops s
        WHERE s.internal_id != v_target_internal_id -- Don't match the target stop with itself here
          AND (
                -- Condition 1: GTFS hierarchy linking (parent/child/sibling)
                -- This applies only if candidate 's' is from the same data_origin as the target.
                (
                    s.data_origin = v_target_data_origin
                    AND (
                        -- Siblings: candidate 's' and target share the same parent_station (parent_station must be non-null and non-empty)
                        (v_target_parent_station IS NOT NULL AND v_target_parent_station <> '' AND s.parent_station = v_target_parent_station)
                        OR
                        -- Candidate 's' is parent of target: target's parent_station matches s.id
                        (v_target_parent_station IS NOT NULL AND v_target_parent_station <> '' AND s.id = v_target_parent_station)
                        OR
                        -- Candidate 's' is child of target: s's parent_station (non-null/empty) matches target's original ID (p_target_stop_id)
                        (s.parent_station IS NOT NULL AND s.parent_station <> '' AND s.parent_station = p_target_stop_id)
                    )
                )
                OR
                -- Condition 2: Name and position check (can link across different data_origins)
                -- This applies if candidate 's' is of the same stop_type as the target.
                (
                    s.stop_type = v_target_stop_type -- Stops must be of the same type for this kind of merge
                    AND (
                        -- Option A: Very close, based on stop_type-dependent strict distance
                        ST_DWithin(
                            geography(s.geo_location), -- candidate stop's location
                            v_target_geo,              -- target stop's location (already geography)
                            v_distance_strict          -- type-dependent strict distance threshold
                        )
                        OR
                        -- Option B: Moderately close (stop_type-dependent loose distance) AND similar name
                        (
                            ST_DWithin(
                                geography(s.geo_location),
                                v_target_geo,
                                v_distance_loose           -- type-dependent loose distance threshold
                            )
                            AND SIMILARITY(s.name, v_target_name) >= v_name_similarity_threshold
                        )
                    )
                )
            )
    )
    INSERT INTO public.related_stops(primary_stop, related_stop, related_data_origin)
    SELECT v_chosen_guid, c.candidate_internal_id, c.candidate_data_origin
    FROM candidates c
    ON CONFLICT (primary_stop, related_stop, related_data_origin) DO NOTHING;

    -- Always insert the target stop itself into the group.
    -- This ensures it's associated with v_chosen_guid, forming a group of at least one,
    -- and correctly links it if candidates were found.
    INSERT INTO public.related_stops(primary_stop, related_stop, related_data_origin)
    VALUES (v_chosen_guid, v_target_internal_id, v_target_data_origin)
    ON CONFLICT (primary_stop, related_stop, related_data_origin) DO NOTHING;

    RAISE NOTICE 'Merge process for target stop (id: %, data_origin: %) completed. Group ID: %.', p_target_stop_id, p_supplier_data_origin, v_chosen_guid;

END;
$BODY$;

-- Set the owner of the procedure if needed, e.g., to 'dennis' as in the prompt
-- ALTER PROCEDURE public.merge_stop(text, text) OWNER TO dennis;