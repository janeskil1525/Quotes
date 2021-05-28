-- 1 up
CREATE SEQUENCE wantedno START 10000;

create table if not exists wanted
(
    wanted_pkey serial not null,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    wanted_no varchar(100) not null,
    wantedstatus VARCHAR NOT NULL DEFAULT 'NEW',
    wanteddate timestamp without time zone NOT NULL DEFAULT NOW(),
    payload JSONB NOT NULL,
    sent BOOLEAN NOT NULL DEFAULT false,
    sentat TIMESTAMP NOT NULL DEFAULT '1900-01-01',
    userid varchar not null default '',
    company varchar not null default '',
    supplier_fkey bigint not null default 0,
    supplier varchar not null default '',
    CONSTRAINT wanted_pkey PRIMARY KEY (wanted_pkey)

);

CREATE unique INDEX idx_wanted_wanted_no_no
    ON public.wanted USING btree
        (wanted_no);

CREATE SEQUENCE quote_no START 10000;

create table if not exists quotes
(
    quotes_pkey serial not null,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    quote_no varchar(100) not null,
    quotestatus VARCHAR NOT NULL DEFAULT 'NEW',
    quotedate timestamp without time zone NOT NULL DEFAULT NOW(),
    sent BOOLEAN NOT NULL DEFAULT false,
    sentat TIMESTAMP NOT NULL DEFAULT '1900-01-01',
    payload jsonb not null,
    userid varchar not null ,
    company varchar not null ,
    supplier varchar not null ,
    CONSTRAINT quotes_pkey PRIMARY KEY (quotes_pkey)

) ;

CREATE unique INDEX if not exists idx_quotes_no
    ON public.quotes USING btree
        (quote_no ASC NULLS LAST);

CREATE INDEX if not exists idx_quotes_userid_company
    ON quotes(userid, company);

CREATE INDEX if not exists idx_quotes_userid
    ON quotes(userid);

CREATE INDEX if not exists idx_quotes_ompany
    ON quotes(company);

CREATE INDEX if not exists idx_quotes_ompany
    ON quotes(supplier);

CREATE SEQUENCE rfqno START 10000;

create table if not exists rfqs
(
    rfqs_pkey serial not null,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Unknown',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    rfq_no varchar(100) not null,
    rfqstatus VARCHAR NOT NULL DEFAULT 'NEW',
    requestdate timestamp without time zone NOT NULL DEFAULT NOW(),
    reqplate varchar(100) not null default '',
    note text not null default '',
    userid varchar(100) not null,
    company varchar(100) not null,
    supplier varchar(100) not null,
    CONSTRAINT rfqs_pkey PRIMARY KEY (rfqs_pkey)
);

CREATE INDEX idx_rfqs_userid ON rfqs(userid);
CREATE INDEX idx_rfqs_company ON rfqs(company);
CREATE INDEX idx_rfqs_supplier ON rfqs(supplier);

CREATE unique INDEX idx_rfqs_rfq_no
    ON public.rfqs USING btree
        (rfq_no ASC NULLS LAST);

ALTER TABLE rfqs
    ADD COLUMN sent BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE rfqs
    ADD COLUMN sentat TIMESTAMP NOT NULL DEFAULT '1900-01-01';

ALTER TABLE rfqs
    RENAME reqplate TO regplate;
-- 1 down