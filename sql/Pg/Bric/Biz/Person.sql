-- Project: Bricolage
-- VERSION: $Revision: 1.2 $
--
-- $Date: 2003-02-12 01:19:40 $
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@wheeler.net>

-- This DDL creates the basic table for all Bric::Person objects. The indexes are
-- suggestions.

-- 
-- TABLE: person 
--

CREATE TABLE person (
    id        NUMERIC(10, 0)    NOT NULL
                                DEFAULT NEXTVAL('seq_person'),
    prefix    VARCHAR(32),
    lname     VARCHAR(64),
    fname     VARCHAR(64),
    mname     VARCHAR(64),
    suffix    VARCHAR(32),
    active    NUMERIC(1, 0)     NOT NULL 
                                DEFAULT 1
                                CONSTRAINT ck_person__active
                                  CHECK (active IN (1,0)),
    CONSTRAINT pk_person__id PRIMARY KEY (id)
);



--
-- TABLE: person_member
--

CREATE TABLE person_member (
    id          NUMERIC(10,0)  NOT NULL
                               DEFAULT NEXTVAL('seq_person_member'),
    object_id   NUMERIC(10,0)  NOT NULL,
    member__id  NUMERIC(10,0)  NOT NULL,
    CONSTRAINT pk_person_member__id PRIMARY KEY (id)
);


-- 
-- INDEXES.
--

CREATE INDEX idx_person__lname ON person(LOWER(lname));
CREATE INDEX idx_person__fname ON person(LOWER(fname));
CREATE INDEX idx_person__mname ON person(LOWER(mname));

CREATE INDEX fkx_person__person_member ON person_member(object_id);
CREATE INDEX fkx_member__person_member ON person_member(member__id);


-- 
-- SEQUENCES.
--

CREATE SEQUENCE seq_person START 1024;
CREATE SEQUENCE seq_person_member START 1024;


