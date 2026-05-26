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