-- Group items by category for the stock tracker UI.

alter table public.items
  add column category text not null default 'Other'
  check (char_length(btrim(category)) between 1 and 40);

update public.items set category = case
  when sku in ('SKU-001', 'SKU-002')                       then 'Dairy'
  when sku in ('SKU-003', 'SKU-004')                       then 'Coffee'
  when sku in ('SKU-009', 'SKU-010', 'SKU-011', 'SKU-012') then 'Powders & syrups'
  when sku = 'SKU-014'                                     then 'Bakery'
  when sku in ('SKU-005', 'SKU-006', 'SKU-007', 'SKU-008', 'SKU-013') then 'Packaging'
  else category
end;

-- Recreate the view to expose category (column order changes, so drop first).
drop view public.stock_latest;
create view public.stock_latest
with (security_invoker = true) as
select distinct on (s.outlet, s.sku)
       s.outlet, s.sku, i.item_name, i.unit, i.category,
       s.qty_on_hand, s.reorder_level,
       s.qty_on_hand <= s.reorder_level as needs_reorder,
       s.counted_at
  from public.stock_counts s
  join public.items i on i.sku = s.sku
 order by s.outlet, s.sku, s.counted_at desc;

revoke all on public.stock_latest from anon;
grant select on public.stock_latest to authenticated;
