-- Project: Bricolage
-- VERSION: $Revision: 1.2.2.1 $
--
-- $Date: 2001-10-09 21:51:07 $
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@wheeler.net>
--


-- 
-- TABLE: alerted 
--

CREATE TABLE alerted(
    id           NUMERIC(10, 0)    NOT NULL
                                   DEFAULT NEXTVAL('seq_alerted'),
    usr__id      NUMERIC(10, 0)    NOT NULL,
    alert__id    NUMERIC(10, 0)    NOT NULL,
    ack_time     TIMESTAMP,
    CONSTRAINT pk_alerted__id PRIMARY KEY (id)
);


-- 
-- TABLE: alerted__contact_value 
--

CREATE TABLE alerted__contact_value(
    alerted__id	            NUMERIC(10, 0)  NOT NULL,
    contact__id             NUMERIC(10, 0)  NOT NULL,
    contact_value__value    VARCHAR(256)    NOT NULL,
    sent_time               TIMESTAMP,
    CONSTRAINT pk_alerted__contact_value PRIMARY KEY (alerted__id, contact__id, contact_value__value)
);

-- 
-- SEQUENCES.
--

CREATE SEQUENCE seq_alerted START  1024;

-- 
-- INDEXES.
--

-- alerted
CREATE INDEX idx_alerted__ack_time ON alerted(ack_time);
CREATE INDEX fkx_alert__alerted ON alerted(alert__id);
CREATE INDEX fkx_usr__alerted ON alerted(usr__id);

-- alerted__contact_value
CREATE INDEX idx_ac_value__sent_time ON alerted__contact_value(sent_time);
CREATE INDEX idx_ac_value__cv__value ON alerted__contact_value(contact_value__value);
CREATE INDEX fkx_alerted__alerted__contact ON alerted__contact_value(alerted__id);
CREATE INDEX fkx_contact__alerted__cont ON alerted__contact_value(contact__id);


