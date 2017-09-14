CREATE OR REPLACE FUNCTION _schema_._table_(_param_ INT)
    RETURNS TABLE(_a_ INT) AS $$
DECLARE
    _b_ INT;
BEGIN
    _b_ := _param_;
    RETURN QUERY
    SELECT _b_;
END;
$$ LANGUAGE plpgsql;
