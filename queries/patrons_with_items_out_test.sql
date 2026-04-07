-- Open loans checked out to patrons with number of days overdue included
DROP FUNCTION IF EXISTS get_users_items_out_test;
CREATE FUNCTION get_users_items_out_test()
RETURNS TABLE(
	patron_group text,
	patron_barcode text)
AS $$
SELECT 	
	users_groups.group AS patron_group,
	users_u.barcode AS patron_barcode
FROM
	folio_circulation.loan__t AS circ_loan
	LEFT JOIN folio_users.groups__t AS users_groups ON users_groups.id = users_u.patron_group
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
