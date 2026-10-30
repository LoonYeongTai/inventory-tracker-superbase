-- Inventory: item catalogue + per-outlet stock counts (one row per outlet/sku/count date).

create table public.items (
  sku        text primary key check (sku ~ '^SKU-[0-9]{3}$'),
  item_name  text not null check (char_length(btrim(item_name)) between 1 and 200),
  unit       text not null check (char_length(btrim(unit)) between 1 and 40),
  created_at timestamptz not null default now()
);

create table public.stock_counts (
  id            bigint generated always as identity primary key,
  outlet        text not null check (char_length(btrim(outlet)) between 1 and 60),
  sku           text not null references public.items (sku) on update cascade,
  qty_on_hand   integer not null check (qty_on_hand >= 0),
  reorder_level integer not null check (reorder_level >= 0),
  counted_at    date not null,
  created_at    timestamptz not null default now(),
  unique (outlet, sku, counted_at)
);

create index stock_counts_sku_idx on public.stock_counts (sku);
create index stock_counts_counted_at_idx on public.stock_counts (counted_at desc);

-- Most recent count per outlet + item, with a reorder flag.
create view public.stock_latest
with (security_invoker = true) as
select distinct on (s.outlet, s.sku)
       s.outlet, s.sku, i.item_name, i.unit,
       s.qty_on_hand, s.reorder_level,
       s.qty_on_hand <= s.reorder_level as needs_reorder,
       s.counted_at
  from public.stock_counts s
  join public.items i on i.sku = s.sku
 order by s.outlet, s.sku, s.counted_at desc;

-- RLS: any signed-in user reads; only profiles.is_admin users write.
-- (Admin check is inlined because authenticated has no usage on schema private.)
alter table public.items enable row level security;
alter table public.stock_counts enable row level security;

create policy items_select on public.items
  for select to authenticated using (true);
create policy items_admin_insert on public.items
  for insert to authenticated
  with check (exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.is_admin));
create policy items_admin_update on public.items
  for update to authenticated
  using (exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.is_admin))
  with check (exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.is_admin));
create policy items_admin_delete on public.items
  for delete to authenticated
  using (exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.is_admin));

create policy stock_counts_select on public.stock_counts
  for select to authenticated using (true);
create policy stock_counts_admin_insert on public.stock_counts
  for insert to authenticated
  with check (exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.is_admin));
create policy stock_counts_admin_update on public.stock_counts
  for update to authenticated
  using (exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.is_admin))
  with check (exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.is_admin));
create policy stock_counts_admin_delete on public.stock_counts
  for delete to authenticated
  using (exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.is_admin));

revoke all on public.items, public.stock_counts, public.stock_latest from anon;
