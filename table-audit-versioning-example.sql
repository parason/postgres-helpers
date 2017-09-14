-- one of audit/versioning approaches to monitor table changes.
-- the idea is to create an audit table which mirrors the original table and has a number of fields to trace the create/update/delete operations.
-- note that using this approach one can not trace the changes caused by TRUNCATE
-- in most of the cases it should perform pretty well

-- cleanup, comment out if not required
DROP TABLE IF EXISTS original.records;
DROP SCHEMA IF EXISTS original CASCADE;
DROP TABLE IF EXISTS audit.records_audit;
DROP SCHEMA IF EXISTS audit CASCADE;

-- Create working schema and talbe
CREATE SCHEMA IF NOT EXISTS original;

CREATE TABLE original.records (
	original_record_id BIGSERIAL   PRIMARY KEY NOT     NULL, -- record identifier
	description        TEXT                    DEFAULT NULL  -- some description text
);

-- create the audit schema, table and required functions
CREATE SCHEMA IF NOT EXISTS audit;

-- create the audit table
CREATE TABLE audit.records_audit (
	LIKE original.records,                            -- same as the original table plus the columns below
	operation      VARCHAR(6)               NOT NULL, -- operation type: create/update/delete
	operation_ts   TIMESTAMP WITH TIME ZONE NOT NULL, -- operation timestamp
	executing_user NAME                     NOT NULL  -- user, executing the operation
);

-- create the required indexes to speed the things up, for example
CREATE INDEX ON audit.records_audit (original_record_id, operation);

-- create original.records table audit trigger
CREATE FUNCTION original.audit_records() RETURNS TRIGGER AS $$
DECLARE
	_row original.records%ROWTYPE;
BEGIN
	IF (TG_OP = 'DELETE') THEN
		_row := OLD;
	ELSE
		_row := NEW;
	END IF;
	INSERT INTO audit.records_audit (
		original_record_id,
		description,
		operation, 
		operation_ts, 
		executing_user)
	 VALUES (_row.original_record_id,
		 _row.description,
		 TG_OP,
		 transaction_timestamp(),
		 session_user);
	RETURN _row;
END;
$$
LANGUAGE plpgsql;

-- attach the database operations to the function above
CREATE TRIGGER bind_audit_original_records
	BEFORE INSERT OR UPDATE OR DELETE
	ON original.records
		FOR EACH ROW
			EXECUTE PROCEDURE original.audit_records();

