-- Project: Bricolage
-- VERSION: $Revision: 1.4 $
--
-- $Date: 2004/03/18 01:54:29 $
-- Target DBMS: PostgreSQL 7.2
-- Author: David Wheeler <david@wheeler.net>

-- This DDL creates the basic table for Bric::Person::Usr objects, and
-- establishes its relationship with Bric::Person. The login field must be unique,
-- hence the udx_usr__login index.


-- 
-- TABLE: usr 
--

CREATE TABLE usr (
    id           NUMERIC(10, 0)    NOT NULL,
    login        VARCHAR(128)      NOT NULL,
    password     CHAR(32)          NOT NULL,
    active       NUMERIC(1, 0)     NOT NULL 
                                   DEFAULT 1
                                   CONSTRAINT ck_usr__active
                                     CHECK (active IN (1,0)),
    CONSTRAINT pk_usr__id PRIMARY KEY (id)
);

-- 
-- INDEXES.
--
CREATE INDEX idx_usr__login ON usr(LOWER(login));
CREATE UNIQUE INDEX udx_usr__login ON usr(LOWER(login)) WHERE active = 1;

