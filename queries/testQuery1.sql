--ldp:function get_users

DROP FUNCTION IF EXISTS get_users;

CREATE FUNCTION get_users(
    start_date date DEFAULT '2000-01-01',
    end_date date DEFAULT '2050-01-01')
RETURNS TABLE(
    id uuid,
    barcode text,
    created_date timestamptz)
AS $$
SELECT id,
       barcode,
       created_date
    FROM user_users
    WHERE start_date <= created_date AND created_date < end_date
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
