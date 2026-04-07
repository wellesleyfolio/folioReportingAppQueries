-- Open loans checked out to patrons with number of days overdue included
DROP FUNCTION IF EXISTS get_users_items_out_test;
CREATE FUNCTION get_users_items_out_test()
RETURNS TABLE(
	Link_to_patron text,
--	loan_status text,
	patron_group text,
	patron_barcode text)
AS $$
SELECT 	
	CONCAT('https://wellesley.folio.ebsco.com/users/preview/',users_u.id::uuid) AS "Link to Patron Record",
--	jsonb_extract_path_text(circ_loan_og.jsonb, 'status', 'name') as loan_status, 
	users_groups.group AS patron_group,
	users_u.barcode AS patron_barcode
FROM
	folio_circulation.loan__t AS circ_loan --folio_reporting.loans_items AS li
	LEFT JOIN folio_circulation.loan__ AS circ_loan_og ON circ_loan_og.id = circ_loan.id AND circ_loan_og.__current = TRUE
	LEFT JOIN folio_users.users__t AS users_u ON users_u.id::uuid = circ_loan.user_id::uuid
	LEFT JOIN folio_users.groups__t AS users_groups ON users_groups.id = users_u.patron_group
--WHERE jsonb_extract_path_text(circ_loan_og.jsonb, 'status', 'name') = 'Open'
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
