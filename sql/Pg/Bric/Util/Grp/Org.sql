-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@wheeler.net>
--

-- 
-- TABLE: org_member 
--

CREATE TABLE org_member (
    id          NUMERIC(10,0)  NOT NULL
                               DEFAULT NEXTVAL('seq_org_member'),
    object_id   NUMERIC(10,0)  NOT NULL,
    member__id  NUMERIC(10,0)  NOT NULL,
    CONSTRAINT pk_org_member__id PRIMARY KEY (id)
);

-- 
-- SEQUENCES.
--

CREATE SEQUENCE seq_org_member START 1024;

--
-- INDEXES.
--
CREATE INDEX fkx_org__org_member ON org_member(object_id);
CREATE INDEX fkx_member__org_member ON org_member(member__id);



