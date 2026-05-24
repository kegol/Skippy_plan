-- Skippy Database Schema
-- PostgreSQL

CREATE TABLE users (
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

CREATE TABLE user_usage (
    user_id       UUID REFERENCES users(id),
    date          DATE NOT NULL DEFAULT CURRENT_DATE,
    queries_used  INT NOT NULL DEFAULT 0,
    PRIMARY KEY (user_id, date)
);

CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_stripe_customer ON users(stripe_customer_id);
CREATE INDEX idx_user_usage_date ON user_usage(date);

-- Plans configuration
CREATE TABLE plans_config (
    plan_name    TEXT PRIMARY KEY,
    daily_limit  INT NOT NULL,
    monthly_price DECIMAL(10,2) NOT NULL DEFAULT 0,
    features     TEXT[] NOT NULL DEFAULT '{}',
    description  TEXT
);

INSERT INTO plans_config VALUES
    ('basic',    5,  0,   ARRAY['calendar_read'], 'Darmowy po trialu. Tylko odczyt kalendarza.'),
    ('premium',  50, 19,  ARRAY['calendar', 'shopping_list', 'reminders'], 'Pełny asystent dnia.'),
    ('family',   100, 29, ARRAY['calendar', 'shopping_list', 'reminders', 'shared_access'], 'Dla całej rodziny.');
