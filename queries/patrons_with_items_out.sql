--/* Open loans checked out to patrons with number of days overdue included*/
DROP FUNCTION IF EXISTS get_users_items_outT;

CREATE FUNCTION get_users_items_outT()
RETURNS TABLE
	(patron_group text,
	patron_barcode text,
    item_location_at_checkout text,
    title text, 
    item_barcode text,
    renewal_count integer,
    item_status text
	)
AS $$
SELECT 	
    users_groups.group AS patron_group,
    users_u.barcode AS patron_barcode,
    inv_loc.name AS item_location_at_checkout,
    inv_inst.index_title AS title,
    inv_item.barcode AS item_barcode,
    circ_loan.renewal_count AS renewal_count,
    circ_loan.item_status AS item_status
FROM
    folio_circulation.loan__t AS circ_loan
    LEFT JOIN folio_users.users__t AS users_u ON (users_u.id = circ_loan.user_id)
    LEFT JOIN folio_users.groups__t AS users_groups ON (users_groups.id = users_u.patron_group)
    LEFT JOIN folio_inventory.item__t AS inv_item ON (inv_item.id = circ_loan.item_id)
    LEFT JOIN folio_inventory.holdings_record__t AS inv_hr ON (inv_hr.id = inv_item.holdings_record_id)
    LEFT JOIN folio_inventory.instance__t AS inv_inst ON (inv_inst.id = inv_hr.instance_id)
	LEFT JOIN folio_inventory.location__t AS inv_loc ON (inv_loc.id = circ_loan.item_effective_location_id_at_check_out)
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
