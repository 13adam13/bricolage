-- Project: Bricolage
-- VERSION: $Revision: 1.2 $
--
-- $Date: 2001-10-09 20:48:54 $
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@wheeler.net>
--


-- 
-- TABLE: alert 
--

CREATE TABLE alert(
    id                NUMERIC(10, 0)    NOT NULL
                                        DEFAULT NEXTVAL('seq_alert'),
    alert_type__id    NUMERIC(10, 0)    NOT NULL,
    event__id         NUMERIC(10, 0)    NOT NULL,
    subject           VARCHAR(128),
    message           VARCHAR(512),
    timestamp         TIMESTAMP         NOT NULL
                                        DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_alert__id PRIMARY KEY (id)
);

-- 
-- SEQUENCES.
--

CREATE SEQUENCE seq_alert START 1024;

-- 
-- INDEXES.
--
 
CREATE INDEX idx_alert__timestamp ON alert(timestamp);
CREATE INDEX fkx_alert_type__alert ON alert(alert_type__id);
CREATE INDEX fkx_event__alert ON alert(event__id);


