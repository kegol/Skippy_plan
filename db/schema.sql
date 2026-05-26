-- Skippy Database Schema
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE SCHEMA IF NOT EXISTS skippy;

CREATE TABLE IF NOT EXISTS skippy.users (
id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
phone TEXT UNIQUE NOT NULL,
name TEXT,
email TEXT,
plan TEXT NOT NULL DEFAULT 'free',
daily_quota INT NOT NULL DEFAULT 5,
stripe_customer_id TEXT,
stripe_subscription_id TEXT,
trial_ends_at TIMESTAMP,
created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS skippy.plans_config (
plan_name TEXT PRIMARY KEY,
monthly_price DECIMAL(10,2) NOT NULL DEFAULT 0,
daily_message_limit INT,
monthly_message_limit INT,
voice_minutes_limit INT,
memory_days INT,
family_members_limit INT,
proactive_enabled BOOLEAN DEFAULT FALSE,
calendar_enabled BOOLEAN DEFAULT FALSE,
shopping_enabled BOOLEAN DEFAULT FALSE,
shared_enabled BOOLEAN DEFAULT FALSE,
description TEXT
);

INSERT INTO skippy.plans_config VALUES
('free',0,5,150,5,7,1,FALSE,TRUE,FALSE,FALSE,'Test produktu'),
('mama',29,30,800,60,60,1,TRUE,TRUE,TRUE,FALSE,'Codzienna organizacja'),
('mama_plus',49,60,1500,180,180,1,TRUE,TRUE,TRUE,FALSE,'Inteligentne planowanie'),
('family',79,100,2500,300,365,5,TRUE,TRUE,TRUE,TRUE,'Rodzinny asystent');

-- UUID-first identity model (phone only at ingress, then user_id everywhere)
CREATE TABLE IF NOT EXISTS skippy.user_identities (
id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
user_id UUID NOT NULL REFERENCES skippy.users(id) ON DELETE CASCADE,
profile_name TEXT NOT NULL DEFAULT 'skippy_plan',
phone_e164 TEXT NOT NULL,
phone_hash TEXT NOT NULL,
is_primary BOOLEAN NOT NULL DEFAULT TRUE,
created_at TIMESTAMP DEFAULT NOW(),
updated_at TIMESTAMP DEFAULT NOW(),
UNIQUE (profile_name, phone_e164),
UNIQUE (profile_name, phone_hash)
);

CREATE INDEX IF NOT EXISTS idx_user_identities_user_id
ON skippy.user_identities(user_id);

CREATE OR REPLACE FUNCTION skippy.normalize_phone(p_phone TEXT)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
cleaned TEXT;
BEGIN
cleaned := regexp_replace(COALESCE(p_phone, ''), '[^0-9+]', '', 'g');
IF cleaned = '' THEN
RETURN NULL;
END IF;

IF left(cleaned, 1) <> '+' THEN
IF left(cleaned, 2) = '48' THEN
cleaned := '+' || cleaned;
ELSE
cleaned := '+48' || cleaned;
END IF;
END IF;

RETURN cleaned;
END;
$$;

CREATE OR REPLACE FUNCTION skippy.phone_hash(p_phone TEXT)
RETURNS TEXT
LANGUAGE sql
AS $$
SELECT encode(digest(COALESCE(skippy.normalize_phone(p_phone), ''), 'sha256'), 'hex');
$$;

CREATE OR REPLACE FUNCTION skippy.resolve_user_id_by_phone(
p_phone TEXT,
p_profile_name TEXT DEFAULT 'skippy_plan'
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
v_phone TEXT;
v_hash TEXT;
v_user_id UUID;
BEGIN
v_phone := skippy.normalize_phone(p_phone);
IF v_phone IS NULL THEN
RAISE EXCEPTION 'Phone cannot be empty';
END IF;

v_hash := skippy.phone_hash(v_phone);

SELECT ui.user_id
INTO v_user_id
FROM skippy.user_identities ui
WHERE ui.profile_name = p_profile_name
AND ui.phone_hash = v_hash
LIMIT 1;

IF v_user_id IS NOT NULL THEN
RETURN v_user_id;
END IF;

INSERT INTO skippy.users(phone)
VALUES (v_phone)
ON CONFLICT (phone) DO UPDATE SET phone = EXCLUDED.phone
RETURNING id INTO v_user_id;

INSERT INTO skippy.user_identities(user_id, profile_name, phone_e164, phone_hash)
VALUES (v_user_id, p_profile_name, v_phone, v_hash)
ON CONFLICT (profile_name, phone_hash) DO NOTHING;

RETURN v_user_id;
END;
$$;

-- Backfill existing users into identity table
INSERT INTO skippy.user_identities(user_id, profile_name, phone_e164, phone_hash)
SELECT u.id,
'skippy_plan' AS profile_name,
skippy.normalize_phone(u.phone) AS phone_e164,
skippy.phone_hash(u.phone) AS phone_hash
FROM skippy.users u
WHERE u.phone IS NOT NULL
ON CONFLICT (profile_name, phone_hash) DO NOTHING;