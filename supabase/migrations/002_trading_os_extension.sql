-- ============================================================
-- Trading Operating System — Extension Migration
-- Non-destructive: only ALTER existing + CREATE new tables
-- Run AFTER 001_initial_schema.sql
-- ============================================================

-- ── ALTER accounts ────────────────────────────────────────────────────────────
ALTER TABLE public.accounts
  ADD COLUMN IF NOT EXISTS account_type    TEXT NOT NULL DEFAULT 'live'
    CHECK (account_type IN ('demo','live','funded')),
  ADD COLUMN IF NOT EXISTS leverage        INTEGER NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS target_balance  NUMERIC(15,2),
  ADD COLUMN IF NOT EXISTS is_archived     BOOLEAN NOT NULL DEFAULT FALSE;

-- ── ALTER trades ──────────────────────────────────────────────────────────────
ALTER TABLE public.trades
  ADD COLUMN IF NOT EXISTS execution_type  TEXT DEFAULT 'market'
    CHECK (execution_type IN ('market','limit','stop')),
  ADD COLUMN IF NOT EXISTS planned_rr      NUMERIC(8,4),
  ADD COLUMN IF NOT EXISTS actual_rr       NUMERIC(8,4),
  ADD COLUMN IF NOT EXISTS slippage        NUMERIC(15,8),
  ADD COLUMN IF NOT EXISTS setup_type      TEXT;

-- ── trade_checklists ─────────────────────────────────────────────────────────
-- Required before saving a trade (pre-trade discipline gate)
CREATE TABLE IF NOT EXISTS public.trade_checklists (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trade_id         UUID NOT NULL REFERENCES public.trades(id) ON DELETE CASCADE,
  user_id          UUID NOT NULL REFERENCES auth.users(id)   ON DELETE CASCADE,
  plan_match       BOOLEAN NOT NULL DEFAULT FALSE,  -- Setup is in trading plan
  risk_ok          BOOLEAN NOT NULL DEFAULT FALSE,  -- Risk ≤ daily max
  rr_ok            BOOLEAN NOT NULL DEFAULT FALSE,  -- R:R meets minimum
  confirmation_ok  BOOLEAN NOT NULL DEFAULT FALSE,  -- Confirmation signal respected
  screenshot_ok    BOOLEAN NOT NULL DEFAULT FALSE,  -- Screenshot attached
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.trade_checklists ENABLE ROW LEVEL SECURITY;
CREATE POLICY "User owns checklists" ON public.trade_checklists
  FOR ALL USING (auth.uid() = user_id);
CREATE INDEX IF NOT EXISTS idx_trade_checklists_trade ON public.trade_checklists(trade_id);

-- ── daily_reviews ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.daily_reviews (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL REFERENCES auth.users(id)      ON DELETE CASCADE,
  account_id            UUID NOT NULL REFERENCES public.accounts(id)  ON DELETE CASCADE,
  review_date           DATE NOT NULL,
  emotional_state       TEXT,
  mistakes_made         TEXT,
  went_well             TEXT,
  plan_adherence        SMALLINT NOT NULL DEFAULT 5
    CHECK (plan_adherence BETWEEN 1 AND 10),
  discipline_score      SMALLINT NOT NULL DEFAULT 5
    CHECK (discipline_score BETWEEN 1 AND 10),
  equity_screenshot_url TEXT,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, account_id, review_date)
);
ALTER TABLE public.daily_reviews ENABLE ROW LEVEL SECURITY;
CREATE POLICY "User owns daily_reviews" ON public.daily_reviews
  FOR ALL USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_daily_reviews_user_date
  ON public.daily_reviews(user_id, review_date);
CREATE INDEX IF NOT EXISTS idx_daily_reviews_account
  ON public.daily_reviews(account_id, review_date);

-- Auto-update updated_at for daily_reviews
CREATE TRIGGER daily_reviews_updated_at
  BEFORE UPDATE ON public.daily_reviews
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ── risk_rules ────────────────────────────────────────────────────────────────
-- One rule set per account; upsert on save
CREATE TABLE IF NOT EXISTS public.risk_rules (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id              UUID NOT NULL REFERENCES auth.users(id)      ON DELETE CASCADE,
  account_id           UUID NOT NULL REFERENCES public.accounts(id)  ON DELETE CASCADE,
  max_daily_loss_pct   NUMERIC(6,4) NOT NULL DEFAULT 2.0,
  max_weekly_loss_pct  NUMERIC(6,4) NOT NULL DEFAULT 5.0,
  max_trades_per_day   INTEGER      NOT NULL DEFAULT 3,
  max_risk_per_trade   NUMERIC(6,4) NOT NULL DEFAULT 1.0,
  min_rr_ratio         NUMERIC(6,4) NOT NULL DEFAULT 1.5,
  created_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, account_id)
);
ALTER TABLE public.risk_rules ENABLE ROW LEVEL SECURITY;
CREATE POLICY "User owns risk_rules" ON public.risk_rules
  FOR ALL USING (auth.uid() = user_id);

CREATE TRIGGER risk_rules_updated_at
  BEFORE UPDATE ON public.risk_rules
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ── discipline_logs ───────────────────────────────────────────────────────────
-- Append-only audit log of every rule violation / skipped review
CREATE TABLE IF NOT EXISTS public.discipline_logs (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES auth.users(id)      ON DELETE CASCADE,
  account_id      UUID NOT NULL REFERENCES public.accounts(id)  ON DELETE CASCADE,
  log_date        DATE NOT NULL DEFAULT CURRENT_DATE,
  violation_type  TEXT NOT NULL,
    -- 'daily_loss' | 'weekly_loss' | 'overtrade' |
    -- 'skipped_daily_review' | 'skipped_weekly_review' |
    -- 'revenge_trade' | 'risk_per_trade'
  details         TEXT,
  trade_id        UUID REFERENCES public.trades(id) ON DELETE SET NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.discipline_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "User owns discipline_logs" ON public.discipline_logs
  FOR ALL USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_discipline_logs_account
  ON public.discipline_logs(account_id, log_date);
CREATE INDEX IF NOT EXISTS idx_discipline_logs_user_date
  ON public.discipline_logs(user_id, log_date);

-- ── ALTER weekly_reviews ──────────────────────────────────────────────────────
ALTER TABLE public.weekly_reviews
  ADD COLUMN IF NOT EXISTS account_id       UUID
    REFERENCES public.accounts(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS discipline_score SMALLINT DEFAULT 5
    CHECK (discipline_score BETWEEN 1 AND 10),
  ADD COLUMN IF NOT EXISTS rule_violations  TEXT,
  ADD COLUMN IF NOT EXISTS improvement_plan TEXT,
  ADD COLUMN IF NOT EXISTS weekly_pnl       NUMERIC(15,2) DEFAULT 0;

-- ── ALTER monthly_reviews ─────────────────────────────────────────────────────
ALTER TABLE public.monthly_reviews
  ADD COLUMN IF NOT EXISTS account_id             UUID
    REFERENCES public.accounts(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS sharpe_ratio           NUMERIC(8,4) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS sortino_ratio          NUMERIC(8,4) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS calmar_ratio           NUMERIC(8,4) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS psychological_summary  TEXT,
  ADD COLUMN IF NOT EXISTS improvement_goals      TEXT,
  ADD COLUMN IF NOT EXISTS strategy_evaluation    TEXT,
  ADD COLUMN IF NOT EXISTS discipline_score       SMALLINT DEFAULT 5
    CHECK (discipline_score BETWEEN 1 AND 10);

-- ── Storage bucket (uncomment and run in Supabase Dashboard SQL editor) ───────
-- INSERT INTO storage.buckets (id, name, public)
-- VALUES ('trade-screenshots', 'trade-screenshots', FALSE)
-- ON CONFLICT DO NOTHING;

-- Storage RLS
-- CREATE POLICY "Auth users manage own screenshots" ON storage.objects
--   FOR ALL USING (
--     bucket_id = 'trade-screenshots'
--     AND auth.uid()::text = (storage.foldername(name))[1]
--   );

-- ============================================================
-- DONE — schema extension complete
-- Run flutter pub get then dart run build_runner build
-- ============================================================
