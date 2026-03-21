#!/bin/bash
# ============================================================
# TradeJournal — Run SQL Migration via Supabase REST API
# This script uses your anon key to create the schema directly
# No browser login required!
# ============================================================

PROJECT_URL="https://oeqehqhzmnaywxqhbofz.supabase.co"
# NOTE: We use the service_role key here (needed for DDL).
# Please paste your SERVICE_ROLE key below.
# Find it at: Supabase Dashboard → Settings → API → service_role (secret)
SERVICE_ROLE_KEY="PASTE_YOUR_SERVICE_ROLE_KEY_HERE"

SQL=$(cat << 'ENDSQL'
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS public.accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  broker TEXT,
  currency TEXT NOT NULL DEFAULT 'USD',
  initial_balance NUMERIC(15,2) NOT NULL DEFAULT 10000,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "User owns accounts" ON public.accounts FOR ALL USING (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.strategies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, name)
);
ALTER TABLE public.strategies ENABLE ROW LEVEL SECURITY;
CREATE POLICY "User owns strategies" ON public.strategies FOR ALL USING (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  color TEXT NOT NULL DEFAULT '#3D7EFF'
);
ALTER TABLE public.tags ENABLE ROW LEVEL SECURITY;
CREATE POLICY "User owns tags" ON public.tags FOR ALL USING (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.trades (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  account_id UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  strategy_id UUID REFERENCES public.strategies(id) ON DELETE SET NULL,
  symbol TEXT NOT NULL,
  asset_class TEXT NOT NULL DEFAULT 'forex',
  direction TEXT NOT NULL DEFAULT 'long',
  entry_price NUMERIC(20,8) NOT NULL,
  exit_price NUMERIC(20,8) NOT NULL,
  stop_loss NUMERIC(20,8),
  take_profit NUMERIC(20,8),
  position_size NUMERIC(20,8) NOT NULL,
  risk_amount NUMERIC(15,2) NOT NULL DEFAULT 0,
  risk_pct NUMERIC(6,4) NOT NULL DEFAULT 0,
  commission NUMERIC(15,2) NOT NULL DEFAULT 0,
  entry_at TIMESTAMPTZ NOT NULL,
  exit_at TIMESTAMPTZ NOT NULL,
  balance_at_entry NUMERIC(15,2) NOT NULL DEFAULT 0,
  gross_pnl NUMERIC(15,2) NOT NULL DEFAULT 0,
  net_pnl NUMERIC(15,2) NOT NULL DEFAULT 0,
  r_multiple NUMERIC(8,4) NOT NULL DEFAULT 0,
  market_condition TEXT,
  session TEXT,
  news_day BOOLEAN NOT NULL DEFAULT FALSE,
  setup_quality SMALLINT NOT NULL DEFAULT 3 CHECK (setup_quality BETWEEN 1 AND 5),
  emotion_before TEXT,
  emotion_after TEXT,
  confidence SMALLINT NOT NULL DEFAULT 3 CHECK (confidence BETWEEN 1 AND 5),
  rules_followed BOOLEAN NOT NULL DEFAULT TRUE,
  is_impulse BOOLEAN NOT NULL DEFAULT FALSE,
  mistake_type TEXT,
  reflection TEXT,
  screenshot_url TEXT,
  mfe NUMERIC(20,8),
  mae NUMERIC(20,8),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_trades_user_entry ON public.trades(user_id, entry_at);
CREATE INDEX IF NOT EXISTS idx_trades_user_symbol ON public.trades(user_id, symbol);
CREATE INDEX IF NOT EXISTS idx_trades_user_strat ON public.trades(user_id, strategy_id);
CREATE INDEX IF NOT EXISTS idx_trades_rules ON public.trades(user_id, rules_followed);
ALTER TABLE public.trades ENABLE ROW LEVEL SECURITY;
CREATE POLICY "User owns trades" ON public.trades FOR ALL USING (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$ BEGIN NEW.updated_at = NOW(); RETURN NEW; END; $$ LANGUAGE plpgsql;

CREATE TRIGGER trades_updated_at
  BEFORE UPDATE ON public.trades
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE IF NOT EXISTS public.trade_tags (
  trade_id UUID NOT NULL REFERENCES public.trades(id) ON DELETE CASCADE,
  tag_id UUID NOT NULL REFERENCES public.tags(id) ON DELETE CASCADE,
  PRIMARY KEY (trade_id, tag_id)
);
ALTER TABLE public.trade_tags ENABLE ROW LEVEL SECURITY;
CREATE POLICY "User owns trade_tags" ON public.trade_tags FOR ALL USING (
  EXISTS (SELECT 1 FROM public.trades t WHERE t.id = trade_id AND t.user_id = auth.uid())
);

CREATE TABLE IF NOT EXISTS public.weekly_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  week_start DATE NOT NULL,
  week_end DATE NOT NULL,
  total_trades INT NOT NULL DEFAULT 0,
  wins INT NOT NULL DEFAULT 0,
  losses INT NOT NULL DEFAULT 0,
  total_r NUMERIC(8,4) NOT NULL DEFAULT 0,
  win_rate NUMERIC(6,4) NOT NULL DEFAULT 0,
  rules_followed_pct NUMERIC(6,4) NOT NULL DEFAULT 0,
  best_trade_id UUID REFERENCES public.trades(id) ON DELETE SET NULL,
  worst_trade_id UUID REFERENCES public.trades(id) ON DELETE SET NULL,
  common_mistake TEXT,
  mental_state_avg NUMERIC(4,2),
  reflection TEXT,
  goals_next_week TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, week_start)
);
ALTER TABLE public.weekly_reviews ENABLE ROW LEVEL SECURITY;
CREATE POLICY "User owns weekly_reviews" ON public.weekly_reviews FOR ALL USING (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.monthly_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  month SMALLINT NOT NULL CHECK (month BETWEEN 1 AND 12),
  year INT NOT NULL,
  total_trades INT NOT NULL DEFAULT 0,
  total_r NUMERIC(8,4) NOT NULL DEFAULT 0,
  win_rate NUMERIC(6,4) NOT NULL DEFAULT 0,
  monthly_return_pct NUMERIC(8,4) NOT NULL DEFAULT 0,
  max_drawdown NUMERIC(8,4) NOT NULL DEFAULT 0,
  expectancy NUMERIC(8,4) NOT NULL DEFAULT 0,
  profit_factor NUMERIC(8,4) NOT NULL DEFAULT 1,
  rules_followed_pct NUMERIC(6,4) NOT NULL DEFAULT 0,
  reflection TEXT,
  goals_next_month TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, year, month)
);
ALTER TABLE public.monthly_reviews ENABLE ROW LEVEL SECURITY;
CREATE POLICY "User owns monthly_reviews" ON public.monthly_reviews FOR ALL USING (auth.uid() = user_id);
ENDSQL
)

echo "Running SQL migration..."
response=$(curl -s -X POST \
  "$PROJECT_URL/rest/v1/rpc/" \
  -H "apikey: $SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"query\": $(echo "$SQL" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')}")

echo "Response: $response"
echo "Done!"
