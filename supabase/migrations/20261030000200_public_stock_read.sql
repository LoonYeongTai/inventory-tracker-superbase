-- Let anyone (signed in or not) view stock; writes stay admin-only.

grant select on public.items, public.stock_counts, public.stock_latest to anon;

create policy items_public_select on public.items
  for select to anon using (true);
create policy stock_counts_public_select on public.stock_counts
  for select to anon using (true);
