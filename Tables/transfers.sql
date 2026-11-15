-- Table: public.transfers

CREATE TABLE public.transfers (
    data_origin character varying(100) NOT NULL,
    id text NOT NULL,
    from_stop_id text,
    to_stop_id text,
    transfer_type integer NOT NULL,
    minimum_transfer_time text,
    internal_id uuid NOT NULL,
    last_updated timestamp with time zone NOT NULL,
    import_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid
);
