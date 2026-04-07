--metadb:fucntion patrons_with_items_out
DROP FUNCTION IF EXISTS patrons;

CREATE FUNCTION patrons()
RETURNS TABLE
	(renewal_count text,
    item_status text
	)
AS $$
SELECT 	
    circ_loan.renewal_count AS renewal_count,
    circ_loan.item_status AS item_status
FROM
    folio_circulation.loan__t circ_loan
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
