-- Let admins grant or remove admin rights from the stock tracker's user management panel.
-- Users, passwords and the other admin_* functions already exist (shared with the meeting tracker).

create or replace function public.admin_set_admin(p_user_id uuid, p_is_admin boolean)
returns void
language plpgsql
security definer
set search_path to ''
as $$
begin
  if not private.is_admin() then
    raise exception 'Only admins can change roles.' using errcode = '42501';
  end if;
  if p_user_id = auth.uid() and not p_is_admin then
    raise exception 'You cannot remove your own admin rights.' using errcode = '22023';
  end if;
  update public.profiles set is_admin = p_is_admin where id = p_user_id;
  if not found then
    raise exception 'That user no longer exists.' using errcode = 'P0002';
  end if;
end $$;

revoke execute on function public.admin_set_admin(uuid, boolean) from public, anon;
grant execute on function public.admin_set_admin(uuid, boolean) to authenticated;
