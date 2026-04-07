--metadb:function checkedOut

DROP FUNCTION IF EXISTS checkedOut;

CREATE FUNCTION checkedOut()
RETURNS TABLE
  (instance_id uuid,
  title text,
  holdings_id uuid,
  call_number text,
  item_id uuid,
  item_barcode text,
  material_type text,
  perm_location text,
  loan_date timestamptz,
  due_date timestamptz,
  item_status text,
  user_barcode text,
  user_email text
  )
AS $$
select
    ii.instance_id as instance_id,
    ii.title as title,
    ih.holdings_id as holdings_id,
    ih.call_number as call_number,
    ii2.item_id as item_id,
    ii2.barcode as item_barcode,
    ii2.material_type_name as material_type,
    ii2.effective_location_name as perm_location,
    cl.loan_date as loan_date,
    cl.loan_due_date as due_date,
    cl.item_status as item_status,
    ug.barcode as user_barcode,
    ug.user_email
from
    folio_derived.instance_ext ii
inner join folio_derived.holdings_ext ih on
    ii.instance_id = ih.instance_id
inner join folio_derived.item_ext ii2 on
    ih.holdings_id = ii2.holdings_record_id
inner join folio_derived.loans_items cl on
    cl.item_id = ii2.item_id
inner join folio_derived.users_groups ug on
    ug.user_id = cl.user_id
where
    cl.item_status = 'Checked out'
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
