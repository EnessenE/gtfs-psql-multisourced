-- Table: public.pathway

CREATE TABLE public.pathway (
    data_origin character varying(100) NOT NULL,
    id text NOT NULL,
    from_stop_id text,
    to_stop_id text,
    pathway_mode integer NOT NULL,
    is_bidirectional integer NOT NULL,
    length double precision,
    traversal_time integer,
    stair_count integer,
    max_slope double precision,
    min_width double precision,
    signposted_as text,
    reversed_signposted_as text,
    internal_id uuid NOT NULL,
    last_updated timestamp with time zone NOT NULL,
    import_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid
);


ALTER TABLE public.pathway OWNER TO postgres;

--
-- Name: stop_times_default; Type: TABLE; Schema: public; Owner: postgres
--
