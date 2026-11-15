-- Table: public.stop_times_default

CREATE TABLE public.stop_times_default (
    internal_id bigint NOT NULL,
    data_origin character varying(100) NOT NULL,
    trip_id text NOT NULL,
    stop_id text NOT NULL,
    stop_sequence bigint NOT NULL,
    arrival_time time without time zone,
    departure_time time without time zone,
    days_since_start_arrival integer DEFAULT 0 NOT NULL,
    days_since_start_departure integer DEFAULT 0 NOT NULL,
    stop_headsign text,
    pickup_type integer,
    drop_off_type integer,
    shape_dist_travelled double precision,
    timepoint_type integer,
    last_updated timestamp with time zone NOT NULL,
    import_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid NOT NULL
);


ALTER TABLE public.stop_times_default OWNER TO postgres;

--
-- Name: stop_times_default; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stop_times ATTACH PARTITION public.stop_times_default DEFAULT;


--
-- Name: pathway pk_pathway; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pathway
    ADD CONSTRAINT pk_pathway PRIMARY KEY (data_origin, id);


--
-- Name: stop_times_default stop_times_default_data_origin_trip_id_stop_id_stop_sequenc_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stop_times_default
    ADD CONSTRAINT stop_times_default_data_origin_trip_id_stop_id_stop_sequenc_key UNIQUE (data_origin, trip_id, stop_id, stop_sequence, import_id);


--
-- Name: stop_times_default stop_times_default_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stop_times_default
    ADD CONSTRAINT stop_times_default_pkey PRIMARY KEY (internal_id, data_origin, import_id);


--
-- Name: ix_pathway_import_id_data_origin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_pathway_import_id_data_origin ON public.pathway USING btree (import_id, data_origin);


--
-- Name: ix_pathway_internal_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_pathway_internal_id ON public.pathway USING btree (internal_id);


--
-- Name: stop_times_default_arrival_time_departure_time_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX stop_times_default_arrival_time_departure_time_idx ON public.stop_times_default USING btree (arrival_time, departure_time);


--
-- Name: stop_times_default_arrival_time_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX stop_times_default_arrival_time_idx ON public.stop_times_default USING btree (arrival_time);


--
-- Name: stop_times_default_data_origin_trip_id_stop_id_stop_sequenc_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX stop_times_default_data_origin_trip_id_stop_id_stop_sequenc_idx ON public.stop_times_default USING btree (data_origin, trip_id, stop_id, stop_sequence, import_id);


--
-- Name: stop_times_default_internal_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX stop_times_default_internal_id_idx ON public.stop_times_default USING btree (internal_id);


--
-- Name: stop_times_default_stop_id_data_origin_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX stop_times_default_stop_id_data_origin_idx ON public.stop_times_default USING btree (stop_id, data_origin);


--
-- Name: stop_times_default_stop_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX stop_times_default_stop_id_idx ON public.stop_times_default USING btree (stop_id);


--
-- Name: stop_times_default_trip_id_data_origin_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX stop_times_default_trip_id_data_origin_idx ON public.stop_times_default USING btree (trip_id, data_origin);


--
-- Name: stop_times_default_arrival_time_departure_time_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.ix_stop_times_arrival_time_departure_time ATTACH PARTITION public.stop_times_default_arrival_time_departure_time_idx;


--
-- Name: stop_times_default_arrival_time_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.ix_stop_times_arrival_time_range ATTACH PARTITION public.stop_times_default_arrival_time_idx;


--
-- Name: stop_times_default_data_origin_trip_id_stop_id_stop_sequenc_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.ix_unique_stop_times ATTACH PARTITION public.stop_times_default_data_origin_trip_id_stop_id_stop_sequenc_idx;


--
-- Name: stop_times_default_data_origin_trip_id_stop_id_stop_sequenc_key; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.unique_stop_times ATTACH PARTITION public.stop_times_default_data_origin_trip_id_stop_id_stop_sequenc_key;


--
-- Name: stop_times_default_internal_id_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.ix_stop_times_pk ATTACH PARTITION public.stop_times_default_internal_id_idx;


--
-- Name: stop_times_default_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.pk_stop_times ATTACH PARTITION public.stop_times_default_pkey;


--
-- Name: stop_times_default_stop_id_data_origin_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.ix_stop_times_stop_id_data_origin ATTACH PARTITION public.stop_times_default_stop_id_data_origin_idx;


--
-- Name: stop_times_default_stop_id_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.ix_stop_times_stop_id ATTACH PARTITION public.stop_times_default_stop_id_idx;


--
-- Name: stop_times_default_trip_id_data_origin_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.ix_stop_times_trip_id_data_origin ATTACH PARTITION public.stop_times_default_trip_id_data_origin_idx;


--
-- Name: TABLE pathway; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.pathway TO pgagent;


--
-- PostgreSQL database dump complete
--

\unrestrict D3iP7dksiwX4f5vJKhd9rEi09ZimXe0GR4KFC1thNrhmla3sGsAhnXyntm6dF3J
