-- size estimate for large tables. works quite good when no exact value is required.
SELECT reltuples::bigint AS estimate FROM pg_class where relname='table_name';

-- get table name in numan readable form
SELECT pg_size_pretty(pg_total_relation_size('_schema_._table_name_'));
