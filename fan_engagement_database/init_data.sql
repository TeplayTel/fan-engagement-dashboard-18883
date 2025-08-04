-- Fan Engagement Database - Initial Data
-- Sample data for development and testing

-- Insert sample teams
INSERT INTO teams (id, name, short_name, logo_url, primary_color, secondary_color) VALUES
    (uuid_generate_v4(), 'Arsenal', 'ARS', '/assets/teams/arsenal-logo.png', '#DC143C', '#FFFFFF'),
    (uuid_generate_v4(), 'Chelsea', 'CHE', '/assets/teams/chelsea-logo.png', '#034694', '#FFFFFF'),
    (uuid_generate_v4(), 'Manchester United', 'MUN', '/assets/teams/manchester-united-logo.png', '#FF0000', '#FFFFFF'),
    (uuid_generate_v4(), 'Manchester City', 'MCI', '/assets/teams/manchester-city-logo.png', '#6CABDD', '#FFFFFF'),
    (uuid_generate_v4(), 'Liverpool', 'LIV', '/assets/teams/liverpool-logo.png', '#C8102E', '#FFFFFF'),
    (uuid_generate_v4(), 'Tottenham Hotspur', 'TOT', '/assets/teams/tottenham-logo.png', '#132257', '#FFFFFF'),
    (uuid_generate_v4(), 'Newcastle United', 'NEW', '/assets/teams/newcastle-logo.png', '#241F20', '#FFFFFF'),
    (uuid_generate_v4(), 'Aston Villa', 'AVL', '/assets/teams/aston-villa-logo.png', '#95BFE5', '#FFFFFF')
ON CONFLICT (name) DO NOTHING;

-- Insert sample emojis for fan reactions
INSERT INTO emojis (id, name, unicode_symbol, category, is_active) VALUES
    (uuid_generate_v4(), 'goal', '⚽', 'celebration', TRUE),
    (uuid_generate_v4(), 'fire', '🔥', 'excitement', TRUE),
    (uuid_generate_v4(), 'heart', '❤️', 'love', TRUE),
    (uuid_generate_v4(), 'thumbs_up', '👍', 'approval', TRUE),
    (uuid_generate_v4(), 'thumbs_down', '👎', 'disapproval', TRUE),
    (uuid_generate_v4(), 'angry', '😠', 'disappointment', TRUE),
    (uuid_generate_v4(), 'sad', '😢', 'disappointment', TRUE),
    (uuid_generate_v4(), 'laugh', '😂', 'amusement', TRUE),
    (uuid_generate_v4(), 'surprised', '😲', 'surprise', TRUE),
    (uuid_generate_v4(), 'clap', '👏', 'applause', TRUE),
    (uuid_generate_v4(), 'facepalm', '🤦', 'frustration', TRUE),
    (uuid_generate_v4(), 'rocket', '🚀', 'excitement', TRUE),
    (uuid_generate_v4(), 'trophy', '🏆', 'victory', TRUE),
    (uuid_generate_v4(), 'lightning', '⚡', 'energy', TRUE),
    (uuid_generate_v4(), 'crown', '👑', 'excellence', TRUE)
ON CONFLICT (name) DO NOTHING;

-- Insert sample matches (using subqueries to get team IDs)
INSERT INTO matches (id, home_team_id, away_team_id, match_date, status, home_score, away_score, competition, venue, video_url)
VALUES
    (
        uuid_generate_v4(),
        (SELECT id FROM teams WHERE name = 'Arsenal' LIMIT 1),
        (SELECT id FROM teams WHERE name = 'Chelsea' LIMIT 1),
        CURRENT_TIMESTAMP + INTERVAL '2 hours',
        'live',
        2,
        1,
        'Premier League',
        'Emirates Stadium',
        '/assets/videos/arsenal-vs-chelsea.mp4'
    ),
    (
        uuid_generate_v4(),
        (SELECT id FROM teams WHERE name = 'Manchester United' LIMIT 1),
        (SELECT id FROM teams WHERE name = 'Manchester City' LIMIT 1),
        CURRENT_TIMESTAMP + INTERVAL '1 day',
        'scheduled',
        0,
        0,
        'Premier League',
        'Old Trafford',
        NULL
    ),
    (
        uuid_generate_v4(),
        (SELECT id FROM teams WHERE name = 'Liverpool' LIMIT 1),
        (SELECT id FROM teams WHERE name = 'Tottenham Hotspur' LIMIT 1),
        CURRENT_TIMESTAMP - INTERVAL '2 days',
        'completed',
        3,
        1,
        'Premier League',
        'Anfield',
        '/assets/videos/liverpool-vs-tottenham.mp4'
    ),
    (
        uuid_generate_v4(),
        (SELECT id FROM teams WHERE name = 'Newcastle United' LIMIT 1),
        (SELECT id FROM teams WHERE name = 'Aston Villa' LIMIT 1),
        CURRENT_TIMESTAMP + INTERVAL '3 days',
        'scheduled',
        0,
        0,
        'Premier League',
        'St. James Park',
        NULL
    );

-- Insert sample match events for completed match
INSERT INTO match_events (match_id, event_type, event_minute, team_id, player_name, description)
SELECT 
    m.id as match_id,
    'goal' as event_type,
    15 as event_minute,
    m.home_team_id as team_id,
    'Mohamed Salah' as player_name,
    'Great finish from inside the box' as description
FROM matches m 
JOIN teams ht ON m.home_team_id = ht.id 
WHERE ht.name = 'Liverpool' AND m.status = 'completed'
LIMIT 1;

INSERT INTO match_events (match_id, event_type, event_minute, team_id, player_name, description)
SELECT 
    m.id as match_id,
    'goal' as event_type,
    32 as event_minute,
    m.home_team_id as team_id,
    'Sadio Mané' as player_name,
    'Header from corner kick' as description
FROM matches m 
JOIN teams ht ON m.home_team_id = ht.id 
WHERE ht.name = 'Liverpool' AND m.status = 'completed'
LIMIT 1;

INSERT INTO match_events (match_id, event_type, event_minute, team_id, player_name, description)
SELECT 
    m.id as match_id,
    'goal' as event_type,
    67 as event_minute,
    m.away_team_id as team_id,
    'Harry Kane' as player_name,
    'Penalty kick conversion' as description
FROM matches m 
JOIN teams at ON m.away_team_id = at.id 
WHERE at.name = 'Tottenham Hotspur' AND m.status = 'completed'
LIMIT 1;

INSERT INTO match_events (match_id, event_type, event_minute, team_id, player_name, description)
SELECT 
    m.id as match_id,
    'goal' as event_type,
    85 as event_type,
    m.home_team_id as team_id,
    'Roberto Firmino' as player_name,
    'Close range finish' as description
FROM matches m 
JOIN teams ht ON m.home_team_id = ht.id 
WHERE ht.name = 'Liverpool' AND m.status = 'completed'
LIMIT 1;

-- Insert sample reactions for the live match
INSERT INTO reactions (match_id, emoji_id, user_session_id, team_preference, match_minute, x_position, y_position)
SELECT 
    m.id as match_id,
    e.id as emoji_id,
    'session_' || generate_random_uuid()::text as user_session_id,
    m.home_team_id as team_preference,
    (random() * 90)::integer as match_minute,
    random() as x_position,
    random() as y_position
FROM matches m
CROSS JOIN emojis e
CROSS JOIN generate_series(1, 50) -- Generate 50 reactions per emoji per match
WHERE m.status = 'live'
LIMIT 500; -- Limit total reactions

-- Insert sample reactions for completed match
INSERT INTO reactions (match_id, emoji_id, user_session_id, team_preference, match_minute, x_position, y_position)
SELECT 
    m.id as match_id,
    e.id as emoji_id,
    'session_' || generate_random_uuid()::text as user_session_id,
    CASE WHEN random() > 0.5 THEN m.home_team_id ELSE m.away_team_id END as team_preference,
    (random() * 90)::integer as match_minute,
    random() as x_position,
    random() as y_position
FROM matches m
CROSS JOIN emojis e
CROSS JOIN generate_series(1, 30) -- Generate 30 reactions per emoji per match
WHERE m.status = 'completed'
LIMIT 300; -- Limit total reactions

-- Create some analytics aggregates for the completed match
INSERT INTO analytics_aggregates (match_id, emoji_id, team_id, aggregate_type, time_period, reaction_count, unique_users)
SELECT 
    r.match_id,
    r.emoji_id,
    r.team_preference as team_id,
    'match_period' as aggregate_type,
    DATE_TRUNC('hour', r.reaction_timestamp) as time_period,
    COUNT(*) as reaction_count,
    COUNT(DISTINCT r.user_session_id) as unique_users
FROM reactions r
JOIN matches m ON r.match_id = m.id
WHERE m.status = 'completed'
GROUP BY r.match_id, r.emoji_id, r.team_preference, DATE_TRUNC('hour', r.reaction_timestamp)
ON CONFLICT (match_id, emoji_id, team_id, aggregate_type, time_period) 
DO UPDATE SET 
    reaction_count = EXCLUDED.reaction_count,
    unique_users = EXCLUDED.unique_users,
    updated_at = CURRENT_TIMESTAMP;

-- Create some additional hourly aggregates
INSERT INTO analytics_aggregates (match_id, emoji_id, team_id, aggregate_type, time_period, reaction_count, unique_users)
SELECT 
    r.match_id,
    r.emoji_id,
    NULL as team_id, -- Overall match analytics
    'hourly' as aggregate_type,
    DATE_TRUNC('hour', r.reaction_timestamp) as time_period,
    COUNT(*) as reaction_count,
    COUNT(DISTINCT r.user_session_id) as unique_users
FROM reactions r
GROUP BY r.match_id, r.emoji_id, DATE_TRUNC('hour', r.reaction_timestamp)
ON CONFLICT (match_id, emoji_id, team_id, aggregate_type, time_period) 
DO UPDATE SET 
    reaction_count = EXCLUDED.reaction_count,
    unique_users = EXCLUDED.unique_users,
    updated_at = CURRENT_TIMESTAMP;

-- Insert some admin-specific data or configurations if needed
-- (This section can be expanded based on admin dashboard requirements)

COMMIT;
