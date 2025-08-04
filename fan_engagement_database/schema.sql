-- Fan Engagement Database Schema
-- PostgreSQL database schema for Fan Engagement Dashboard

-- Create database (if needed, this would be run separately)
-- CREATE DATABASE fan_engagement;

-- Connect to the database
-- \c fan_engagement;

-- Enable UUID extension for generating unique IDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Teams table to store team information
CREATE TABLE IF NOT EXISTS teams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    short_name VARCHAR(10) NOT NULL,
    logo_url VARCHAR(255),
    primary_color VARCHAR(7) DEFAULT '#000000', -- Hex color code
    secondary_color VARCHAR(7) DEFAULT '#FFFFFF',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Matches table to store match information
CREATE TABLE IF NOT EXISTS matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    home_team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    away_team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    match_date TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'scheduled', -- scheduled, live, completed, postponed
    home_score INTEGER DEFAULT 0,
    away_score INTEGER DEFAULT 0,
    competition VARCHAR(100) NOT NULL,
    venue VARCHAR(100),
    match_duration INTEGER DEFAULT 90, -- in minutes
    video_url VARCHAR(255), -- URL to match video/stream
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT different_teams CHECK (home_team_id != away_team_id)
);

-- Emojis table to store available emoji reactions
CREATE TABLE IF NOT EXISTS emojis (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) NOT NULL UNIQUE,
    unicode_symbol VARCHAR(10) NOT NULL,
    category VARCHAR(50) DEFAULT 'general', -- general, celebration, disappointment, etc.
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- User reactions table to store fan reactions during matches
CREATE TABLE IF NOT EXISTS reactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    emoji_id UUID NOT NULL REFERENCES emojis(id) ON DELETE CASCADE,
    user_session_id VARCHAR(255) NOT NULL, -- Session-based identification (no user auth)
    team_preference UUID REFERENCES teams(id), -- Which team the user is supporting
    reaction_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    match_minute INTEGER, -- Minute in the match when reaction occurred
    x_position FLOAT CHECK (x_position >= 0 AND x_position <= 1), -- Normalized position (0-1)
    y_position FLOAT CHECK (y_position >= 0 AND y_position <= 1), -- Normalized position (0-1)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Analytics aggregates table for performance optimization
CREATE TABLE IF NOT EXISTS analytics_aggregates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    emoji_id UUID NOT NULL REFERENCES emojis(id) ON DELETE CASCADE,
    team_id UUID REFERENCES teams(id), -- Team-specific analytics
    aggregate_type VARCHAR(50) NOT NULL, -- hourly, daily, match_period, etc.
    time_period TIMESTAMP WITH TIME ZONE NOT NULL,
    reaction_count INTEGER DEFAULT 0,
    unique_users INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(match_id, emoji_id, team_id, aggregate_type, time_period)
);

-- Match events table for storing key match events
CREATE TABLE IF NOT EXISTS match_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL, -- goal, card, substitution, etc.
    event_minute INTEGER NOT NULL,
    team_id UUID REFERENCES teams(id),
    player_name VARCHAR(100),
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_matches_status ON matches(status);
CREATE INDEX IF NOT EXISTS idx_matches_date ON matches(match_date);
CREATE INDEX IF NOT EXISTS idx_matches_home_team ON matches(home_team_id);
CREATE INDEX IF NOT EXISTS idx_matches_away_team ON matches(away_team_id);

CREATE INDEX IF NOT EXISTS idx_reactions_match ON reactions(match_id);
CREATE INDEX IF NOT EXISTS idx_reactions_emoji ON reactions(emoji_id);
CREATE INDEX IF NOT EXISTS idx_reactions_timestamp ON reactions(reaction_timestamp);
CREATE INDEX IF NOT EXISTS idx_reactions_session ON reactions(user_session_id);
CREATE INDEX IF NOT EXISTS idx_reactions_team ON reactions(team_preference);

CREATE INDEX IF NOT EXISTS idx_analytics_match ON analytics_aggregates(match_id);
CREATE INDEX IF NOT EXISTS idx_analytics_time ON analytics_aggregates(time_period);
CREATE INDEX IF NOT EXISTS idx_analytics_type ON analytics_aggregates(aggregate_type);

CREATE INDEX IF NOT EXISTS idx_match_events_match ON match_events(match_id);
CREATE INDEX IF NOT EXISTS idx_match_events_minute ON match_events(event_minute);

-- Triggers to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_teams_updated_at BEFORE UPDATE ON teams FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_matches_updated_at BEFORE UPDATE ON matches FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_emojis_updated_at BEFORE UPDATE ON emojis FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_analytics_updated_at BEFORE UPDATE ON analytics_aggregates FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create a view for match details with team information
CREATE OR REPLACE VIEW match_details AS
SELECT 
    m.id,
    m.match_date,
    m.status,
    m.home_score,
    m.away_score,
    m.competition,
    m.venue,
    m.video_url,
    ht.name as home_team_name,
    ht.short_name as home_team_short,
    ht.logo_url as home_team_logo,
    ht.primary_color as home_team_color,
    at.name as away_team_name,
    at.short_name as away_team_short,
    at.logo_url as away_team_logo,
    at.primary_color as away_team_color,
    m.created_at,
    m.updated_at
FROM matches m
JOIN teams ht ON m.home_team_id = ht.id
JOIN teams at ON m.away_team_id = at.id;

-- Create a view for reaction analytics
CREATE OR REPLACE VIEW reaction_analytics AS
SELECT 
    m.id as match_id,
    m.home_team_id,
    m.away_team_id,
    e.name as emoji_name,
    e.unicode_symbol,
    COUNT(r.id) as total_reactions,
    COUNT(DISTINCT r.user_session_id) as unique_users,
    AVG(r.match_minute) as avg_reaction_minute
FROM matches m
LEFT JOIN reactions r ON m.id = r.match_id
LEFT JOIN emojis e ON r.emoji_id = e.id
GROUP BY m.id, m.home_team_id, m.away_team_id, e.id, e.name, e.unicode_symbol;
