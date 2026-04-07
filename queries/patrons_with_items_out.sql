--metadb:fucntion patrons_with_items_out
DROP FUNCTION IF EXISTS patrons_with_items_out;

CREATE FUNCTION patrons_with_items_out()
RETURNS TABLE
	(patron_barcode text,
    renewal_count integer,
    item_status text
	)
AS $$
SELECT 	
    users_u.barcode AS patron_barcode,
    circ_loan.renewal_count AS renewal_count,
    circ_loan.item_status AS item_status
FROM
    folio_circulation.loan__t circ_loan
    LEFT JOIN folio_users.users__t users_u ON (users_u.id = circ_loan.user_id)
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
