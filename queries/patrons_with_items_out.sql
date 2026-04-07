--metadb:function get_users_items_out
DROP FUNCTION IF EXISTS get_users_items_out;
CREATE FUNCTION get_users_items_out(
	userGroup1 varchar DEFAULT '',
	userGroup2 varchar DEFAULT '',
	userGroup3 varchar DEFAULT '',
	expirationDateStart date DEFAULT '2000-01-01',
	expirationDateEnd date DEFAULT '2050-01-01')
RETURNS TABLE(
	Link_to_patron text,
	loan_status text,
	patron_group text,
	patron_barcode text,
	first_name text,
	preferred_first_name text,
	middle_name text,
	last_name text,	
	email text,
	affiliation_note text,
	department_or_major text,
	user_note text,
	patron_expiration_date text,
	item_location_at_checkout text,
	title text, 
	call_number text,
	vol_chron_enum text,
	item_barcode text,
	renewal_count integer,
	due_date text,
	item_status text,
	checked_out_date text,
    days_overdue integer,
	patron_uuid uuid)
AS $$
WITH days AS (
  SELECT 
    id,
    DATE_PART('day', NOW() - due_date) AS days_overdue
    FROM folio_circulation.loan__t 
)
SELECT 	
	CONCAT('https://wellesley.folio.ebsco.com/users/preview/',users_u.id::uuid) AS "Link to Patron Record",
	circ_loan_og.jsonb#>>'{status,name}' as loan_status,
	users_groups.group AS patron_group,
	users_u.barcode AS patron_barcode,
	users_u_og.jsonb#>>'{personal,firstName}' as first_name,
	users_u_og.jsonb#>>'{personal,preferredFirstName}' as preferred_first_name,
	users_u_og.jsonb#>>'{personal,middleName}' AS middle_name,
	users_u_og.jsonb#>>'{personal,lastName}' as last_name,
	users_u_og.jsonb#>>'{personal,email}' AS email,
	users_u_og.jsonb#>>'{customFields,affiliationNote}' AS affiliation_note,
	users_u_og.jsonb#>>'{customFields,departmentOrMajor}' AS department_or_major,
	users_u_og.jsonb#>>'{customFields,userNote}' AS user_note,
	to_char(users_u.expiration_date,'MM-DD-YYYY') AS patron_expiration_date,
	inv_loc.name AS item_location_at_checkout,
	inv_inst.index_title AS title,
	CASE --GETS concat prefix and call number from item record OTHERWISE GETS holdings prefix and callnumber 
		WHEN CONCAT(inv_item.item_level_call_number_prefix,inv_item.item_level_call_number) > '' THEN CONCAT(inv_item.item_level_call_number_prefix,inv_item.item_level_call_number)
		ELSE CONCAT(inv_hr.call_number_prefix,inv_hr.call_number) 
	END AS call_number,
	CONCAT(inv_item.volume,inv_item.chronology,inv_item.enumeration) AS vol_chron_enum,
	inv_item.barcode AS item_barcode,
	circ_loan.renewal_count AS renewal_count,
	to_char(circ_loan.due_date,'MM-DD-YYYY HH24:MM AM') AS due_date,
	circ_loan.item_status AS item_status,
	to_char(circ_loan.loan_date,'MM-DD-YYYY HH24:MM AM') AS checked_out_date,
	DATE_PART('day', NOW() - circ_loan.due_date) AS days_overdue,
	users_u.id AS patron_uuid
FROM
	folio_circulation.loan__t AS circ_loan --folio_reporting.loans_items AS li
	LEFT JOIN folio_circulation.loan__ AS circ_loan_og ON circ_loan_og.id = circ_loan.id AND circ_loan_og.__current = TRUE
	LEFT JOIN folio_users.users__t AS users_u ON users_u.id::uuid = circ_loan.user_id::uuid
	LEFT JOIN folio_users.groups__t AS users_groups ON users_groups.id = users_u.patron_group
	LEFT JOIN folio_users.users AS users_u_og ON users_u.id::uuid = users_u_og.id
	LEFT JOIN folio_inventory.item__t AS inv_item ON inv_item.id = circ_loan.item_id
	LEFT JOIN folio_inventory.holdings_record__t AS inv_hr ON inv_hr.id = inv_item.holdings_record_id
	LEFT JOIN folio_inventory.instance__t AS inv_inst ON inv_inst.id = inv_hr.instance_id
	LEFT JOIN folio_inventory.location__t AS inv_loc ON inv_loc.id = circ_loan.item_effective_location_id_at_check_out
	LEFT JOIN days ON days.id = circ_loan.id
WHERE circ_loan_og.jsonb#>>'{status,name}' = 'Open' 
	AND (users_groups.group = userGroup1 OR users_groups.group = userGroup2 OR users_groups.group = userGroup3)
--	AND (users_u.expiration_date BETWEEN expirationDateStart AND expirationDateEnd)
ORDER BY users_groups.group ASC, users_u_og.jsonb#>>'{personal,lastName}' ASC, users_u_og.jsonb#>>'{personal,firstName}' ASC, inv_item.effective_shelving_order ASC
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
