--metadb:function TRC

DROP FUNCTION IF EXISTS TRC;

CREATE FUNCTION TRC()
RETURNS TABLE
  (title text,
  contributor_name text,
  call_number text,
  date_of_publication text,
  copy_number text,
  volume text,
  barcode text,
  material_type_name text,
  location_name text,
  loans integer
  )
AS $$
with inst_contributors as (
  select ic.instance_id, ic.contributor_name
  from folio_derived.instance_contributors ic where ic.contributor_is_primary='TRUE'
  group by ic.instance_id,ic.contributor_name
  ),
inst_publishers as (
  select ip.instance_id, ip.publisher, ip.date_of_publication
  from folio_derived.instance_publication ip where ip.publication_ordinality='1'
  group by ip.instance_id, ip.publisher, ip.date_of_publication),
total_loans as
  (
  select jsonb_extract_path_text(loan.jsonb, 'itemId') :: uuid as item_id, 
  count(*) as loans
  from folio_circulation.loan
  /*where jsonb_extract_path_text(loan.jsonb, 'loanDate') :: date between '2024-09-01' and '2026-02-03'*/
  group by item_id
  )
select 
  it.title,
  ic2.contributor_name,
  hrt.call_number, 
  ip2.date_of_publication,
  ie.copy_number,
  ie.volume,
  ie.barcode, 
  ie.material_type_name, 
  lt.name as location_name,
  tl.loans
from folio_derived.item_ext ie
left join folio_inventory.item__t it2 on (it2.id = ie.item_id) 
left join folio_inventory.holdings_record__t hrt on (ie.holdings_record_id = hrt.id)
left join folio_inventory.location__t__ lt on (hrt.permanent_location_id = lt.id)
left join folio_inventory.instance__t it on (hrt.instance_id = it.id)
left join inst_contributors ic2 on (it.id = ic2.instance_id)
left join inst_publishers ip2 on (it.id = ip2.instance_id) 
left join total_loans tl on (tl.item_id::uuid = ie.item_id::uuid)
where lt.name like '%Recreational%'
order by it2.effective_shelving_order, ie.copy_number, ie.volume
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
