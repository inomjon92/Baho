-- Xarid Baho: jadvallar (prefiks: xb_)
create table if not exists public.xb_purchases (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  user_id text not null check (length(user_id) between 6 and 80),
  user_name text not null default 'Mehmon' check (length(user_name) <= 60),
  title text not null check (length(title) between 2 and 120),
  price bigint not null check (price > 0 and price < 100000000000),
  store text not null check (length(store) <= 40),
  category text not null check (length(category) <= 30),
  photo_url text check (photo_url is null or length(photo_url) <= 500),
  note text check (note is null or length(note) <= 300)
);
create index if not exists xb_purchases_created_idx on public.xb_purchases (created_at desc);
create index if not exists xb_purchases_user_idx on public.xb_purchases (user_id);

create table if not exists public.xb_votes (
  purchase_id uuid not null references public.xb_purchases(id) on delete cascade,
  user_id text not null check (length(user_id) between 6 and 80),
  price_vote text not null check (price_vote in ('arzon','normal','qimmat')),
  buy_vote boolean not null,
  created_at timestamptz not null default now(),
  primary key (purchase_id, user_id)
);

alter table public.xb_purchases enable row level security;
alter table public.xb_votes enable row level security;

drop policy if exists xb_p_read on public.xb_purchases;
create policy xb_p_read on public.xb_purchases for select to anon, authenticated using (true);
drop policy if exists xb_p_ins on public.xb_purchases;
create policy xb_p_ins on public.xb_purchases for insert to anon, authenticated with check (true);

drop policy if exists xb_v_read on public.xb_votes;
create policy xb_v_read on public.xb_votes for select to anon, authenticated using (true);
drop policy if exists xb_v_ins on public.xb_votes;
create policy xb_v_ins on public.xb_votes for insert to anon, authenticated with check (true);

-- Statistika
create or replace view public.xb_feed with (security_invoker = on) as
select p.*,
  count(v.*)::int as votes,
  count(*) filter (where v.price_vote='arzon')::int as arzon,
  count(*) filter (where v.price_vote='normal')::int as normal,
  count(*) filter (where v.price_vote='qimmat')::int as qimmat,
  count(*) filter (where v.buy_vote)::int as ol,
  count(*) filter (where v.buy_vote = false)::int as olma
from public.xb_purchases p
left join public.xb_votes v on v.purchase_id = p.id
group by p.id;

-- Rasmlar
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('xb-photos','xb-photos', true, 3145728, array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;

drop policy if exists xb_photo_ins on storage.objects;
create policy xb_photo_ins on storage.objects for insert to anon, authenticated
  with check (bucket_id = 'xb-photos');
