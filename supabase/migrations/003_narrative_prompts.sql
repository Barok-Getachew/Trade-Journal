-- ── 003_narrative_prompts.sql ─────────────────────────────────────────────────
-- Daily narrative (one per day per user)

CREATE TABLE IF NOT EXISTS public.daily_narratives (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id              UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  narrative_date       DATE NOT NULL,
  pair                 TEXT,
  session              TEXT,
  -- 5 ICT pre-session sentences
  s1_htf_bias          TEXT,
  s2_price_action      TEXT,
  s3_liquidity_draw    TEXT,
  s4_path              TEXT,
  s5_execution         TEXT,
  -- Post-trade attachment
  post_s5_complete     BOOLEAN,
  post_delivered       BOOLEAN,
  post_breakdown       TEXT,
  post_emotional_state TEXT,
  post_prepared_version TEXT,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, narrative_date)
);

ALTER TABLE public.daily_narratives ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own daily narratives"
  ON public.daily_narratives
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ── Weekly narrative (one per week per user) ──────────────────────────────────

CREATE TABLE IF NOT EXISTS public.weekly_narratives (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                 UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  week_of                 DATE NOT NULL,
  primary_instrument      TEXT,
  high_impact_news        TEXT,
  -- 5 steps
  step1_cot               TEXT,
  step2_htf_structure     TEXT,
  liquidity_map           JSONB,
  step4_amd               TEXT,
  scenario_a              TEXT,
  scenario_b              TEXT,
  -- Weekly reflection (fill Friday)
  refl_scenario_played    TEXT,
  refl_amd_correct        BOOLEAN,
  refl_cleanest_day       TEXT,
  refl_complete_s5_count  INTEGER,
  refl_carry_forward      TEXT,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, week_of)
);

ALTER TABLE public.weekly_narratives ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own weekly narratives"
  ON public.weekly_narratives
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
