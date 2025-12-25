-- Prism MVP Schema
-- 5 columns, simple

create table if not exists prisms (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  definition jsonb not null,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

-- Index for user queries
create index if not exists prisms_user_id_idx on prisms(user_id);

-- RLS
alter table prisms enable row level security;

-- Owner full access (insert, update, delete)
create policy "Users can manage own prisms"
  on prisms for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Public read access (sharing by UUID)
-- Anyone can read any prism if they know the UUID
create policy "Public read access for sharing"
  on prisms for select
  using (true);

-- Auto-update timestamp
create or replace function update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger prisms_updated_at
  before update on prisms
  for each row execute function update_updated_at();
