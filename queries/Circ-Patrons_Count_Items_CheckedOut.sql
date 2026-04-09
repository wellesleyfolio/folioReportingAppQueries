--metadb:function patron_count_items_checkedOut

DROP FUNCTION IF EXISTS patron_count_items_checkedOut;

CREATE FUNCTION patron_count_items_checkedOut()
RETURNS TABLE
  (       
  Link_to_Patron_Record text,
  patron_group text,
  loan_count integer,
  name text,
  email text,
	affiliation_note text,
  department_or_major text,
  user_note text,
  patron_expiration_date text,
  patron_barcode text,
  last_name text,
  first_name_pref text,
  middle_name text
  )
AS $$
WITH itemsout AS (
SELECT 
    circ_loan.id,
	circ_loan.user_id,
	circ_loan_og.jsonb#>>'{status,name}' as loan_status,
    inv_loc.name AS "item location at checkout",
    inv_inst.index_title AS "title",
    CASE --GETS concat prefix and call number from item record OTHERWISE GETS holdings prefix and callnumber 
	    WHEN CONCAT(inv_item.item_level_call_number_prefix,inv_item.item_level_call_number) > '' THEN CONCAT(inv_item.item_level_call_number_prefix,inv_item.item_level_call_number)
        ELSE CONCAT(inv_hr.call_number_prefix,inv_hr.call_number) 
        END AS "call number",
    CONCAT(inv_item.volume,inv_item.chronology,inv_item.enumeration) AS "vol/chron/enum",
    inv_item.barcode AS "item barcode",
    circ_loan.renewal_count AS "renewal count",
    to_char(circ_loan.due_date,'MM-DD-YYYY HH24:MM AM') AS "due date",
    circ_loan.item_status AS "item status",
    to_char(circ_loan.loan_date,'MM-DD-YYYY HH24:MM AM') AS "checked out date"
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
WHERE circ_loan_og.jsonb#>>'{status,name}' = 'Open'
ORDER BY circ_loan.user_id
    )
SELECT 	 
   CONCAT('https://wellesley.folio.ebsco.com/users/preview/',users_u.id::uuid) AS "Link to Patron Record",
   users_groups.group AS "patron group",
   loan_count,
   CONCAT((CASE --GETS preferred firstname OTHERWISE GETS firstname
	   WHEN users_u_og.jsonb#>>'{personal,preferredFirstName}' <> '' THEN users_u_og.jsonb#>>'{personal,preferredFirstName}'
     ELSE users_u_og.jsonb#>>'{personal,firstName}'
     END),' ', (CASE WHEN users_u_og.jsonb#>>'{personal,middleName}' <> '' THEN CONCAT(users_u_og.jsonb#>>'{personal,middleName}',' ') ELSE '' END), users_u_og.jsonb#>>'{personal,lastName}') as "Name",
	 users_u_og.jsonb#>>'{personal,email}' AS "email",
	 users_u_og.jsonb#>>'{customFields,affiliationNote}' AS "affiliation note",
   users_u_og.jsonb#>>'{customFields,departmentOrMajor}' AS "department or major",
   users_u_og.jsonb#>>'{customFields,userNote}' AS "user note",
   to_char(users_u.expiration_date,'MM-DD-YYYY') AS "patron expiration date",
   users_u.barcode AS "patron barcode",
   users_u_og.jsonb#>>'{personal,lastName}' as "last name",
   CASE --GETS preferred firstname OTHERWISE GETS firstname
	   WHEN users_u_og.jsonb#>>'{personal,preferredFirstName}' <> '' THEN users_u_og.jsonb#>>'{personal,preferredFirstName}'
     ELSE users_u_og.jsonb#>>'{personal,firstName}'
     END AS "first name (pref)",
   users_u_og.jsonb#>>'{personal,middleName}' AS "middle name"
 --    users_u.id AS "patron uuid"
FROM
    folio_users.users__t AS users_u --ON users_u.id::uuid = circ_loan.user_id::uuid
    LEFT JOIN folio_users.groups__t AS users_groups ON users_groups.id = users_u.patron_group
    LEFT JOIN folio_users.users AS users_u_og ON users_u.id::uuid = users_u_og.id
    LEFT JOIN (SELECT user_id,
       count(*) AS loan_count
    FROM itemsout AS io
    GROUP BY user_id) AS virtual_table ON virtual_table.user_id = users_u.id /*end section*/
WHERE loan_count > '0'--users_u.expiration_date < '2029-12-31%' AND  AND users_groups.group <> 'Wellesley faculty or staff' 
ORDER BY users_groups.group ASC, users_u_og.jsonb#>>'{personal,lastName}' ASC, users_u_og.jsonb#>>'{personal,firstName}' ASC ;
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
