-- Project: Bricolage
-- VERSION: $Revision: 1.2 $
--
-- $Date: 2003-10-14 00:36:41 $
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@wheeler.net>
--

--
-- SEQUENCES.
--
CREATE SEQUENCE seq_job START 1024;
CREATE SEQUENCE seq_job_member START 1024;

-- 
-- TABLE: job 
--

CREATE TABLE job (
    id            NUMERIC(10, 0)    NOT NULL
                                    DEFAULT NEXTVAL('seq_job'),
    name          VARCHAR(256)      NOT NULL,
    usr__id       NUMERIC(10, 0)    NOT NULL,
    sched_time    TIMESTAMP	    NOT NULL
				    DEFAULT CURRENT_TIMESTAMP,
    comp_time     TIMESTAMP,
    expire        NUMERIC(1, 0)     NOT NULL
                                    DEFAULT 0
                                    CONSTRAINT ck_job__expire
				      CHECK (expire IN (1,0)),
    tries	  NUMERIC(2, 0)	    NOT NULL
				    DEFAULT 0
                                    CONSTRAINT ck_job__tries
				      CHECK (tries BETWEEN 0 AND 10),
    pending       NUMERIC(1, 0)     NOT NULL 
                                    DEFAULT 0
                                    CONSTRAINT ck_job__pending
				      CHECK (pending IN (1,0)),
    CONSTRAINT pk_job__id PRIMARY KEY (id)
);


-- 
-- TABLE: job__resource 
--

CREATE TABLE job__resource(
    job__id         NUMERIC(10, 0)    NOT NULL,
    resource__id    NUMERIC(10, 0)    NOT NULL,
    CONSTRAINT pk_job__resource PRIMARY KEY (job__id,resource__id)
);


-- 
-- TABLE: job__server_type 
--

CREATE TABLE job__server_type(
    job__id            NUMERIC(10, 0)  NOT NULL,
    server_type__id     NUMERIC(10, 0) NOT NULL,
    CONSTRAINT pk_job__server_type PRIMARY KEY (job__id,server_type__id)
);

--
-- TABLE: job_member
--

CREATE TABLE job_member (
    id          NUMERIC(10,0)  NOT NULL
                               DEFAULT NEXTVAL('seq_job_member'),
    object_id   NUMERIC(10,0)  NOT NULL,
    member__id  NUMERIC(10,0)  NOT NULL,
    CONSTRAINT pk_job_member__id PRIMARY KEY (id)
);


-- 
-- INDEXES. 
--
CREATE INDEX idx_job__name ON job(LOWER(name));
CREATE INDEX idx_job__sched_time ON job(sched_time);
CREATE INDEX idx_job__comp_time ON job(comp_time);
CREATE INDEX idx_job__comp_time__is_null ON job(comp_time) WHERE comp_time is NULL;

CREATE INDEX fkx_job__job__resource ON job__resource(job__id);
CREATE INDEX fkx_usr__job ON job (usr__id);
CREATE INDEX fkx_resource__job__resource ON job__resource(resource__id);
CREATE INDEX fkx_job__job__server_type ON job__server_type(job__id);
CREATE INDEX fkx_srvr_type__job__srvr_type ON job__server_type(server_type__id);

CREATE INDEX fkx_job__job_member ON job_member(object_id);
CREATE INDEX fkx_member__job_member ON job_member(member__id);


