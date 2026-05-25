-- Skippy Database Schema
-- PostgreSQL

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE SCHEMA IF NOT EXISTS skippy;

CREATE TABLE IF NOT EXISTS skippy.users (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone                 TEXT UNIQUE NOT NULL,
    name                  TEXT,
    email                 TEXT,
    plan                  TEXT NOT NULL DEFAULT 'basic',
    daily_quota           INT NOT NULL DEFAULT 20,
    stripe_customer_id    TEXT,
    stripe_subscription_id TEXT,
    trial_ends_at         TIMESTAMP,
    calendar_token        TEXT,
    calendar_refresh_token TEXT,
    calendar_email        TEXT,
    onboarded             BOOLEAN DEFAULT FALSE,
    created_at            TIMESTAMP DEFAULT NOW(),
    updated_at            TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS skippy.user_usage (
    user_id       UUID REFERENCES skippy.users(id),
    date          DATE NOT NULL DEFAULT CURRENT_DATE,
    queries_used  INT NOT NULL DEFAULT 0,
    PRIMARY KEY (user_id, date)
);

CREATE INDEX IF NOT EXISTS idx_users_phone ON skippy.users(phone);
CREATE INDEX IF NOT EXISTS idx_users_stripe_customer ON skippy.users(stripe_customer_id);
CREATE INDEX IF NOT EXISTS idx_user_usage_date ON skippy.user_usage(date);

CREATE TABLE IF NOT EXISTS skippy.whatsapp_users (
    id BIGSERIAL PRIMARY KEY,
    phone TEXT UNIQUE NOT NULL,
    full_name TEXT,
    first_seen_at TIMESTAMP DEFAULT NOW(),
    last_seen_at TIMESTAMP DEFAULT NOW(),
    onboarding_status TEXT DEFAULT 'pending',
    source TEXT DEFAULT 'whatsapp'
);

CREATE INDEX IF NOT EXISTS idx_whatsapp_users_phone ON skippy.whatsapp_users(phone);

-- Plans configuration
CREATE TABLE IF NOT EXISTS skippy.plans_config (
    plan_name    TEXT PRIMARY KEY,
    daily_limit  INT NOT NULL,
    monthly_price DECIMAL(10,2) NOT NULL DEFAULT 0,
    features     TEXT[] NOT NULL DEFAULT '{}',
    description  TEXT
);

INSERT INTO skippy.plans_config VALUES
    ('basic',    5,  0,   ARRAY['calendar_read'], 'Darmowy po trialu. Tylko odczyt kalendarza.'),
    ('premium',  50, 19,  ARRAY['calendar', 'shopping_list', 'reminders'], 'Pełny asystent dnia.'),
    ('family',   100, 29, ARRAY['calendar', 'shopping_list', 'reminders', 'shared_access'], 'Dla całej rodziny.')
ON CONFLICT (plan_name) DO UPDATE SET
    daily_limit = EXCLUDED.daily_limit,
    monthly_price = EXCLUDED.monthly_price,
    features = EXCLUDED.features,
    description = EXCLUDED.description;
