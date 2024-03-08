CREATE TABLE users (
  	id SERIAL PRIMARY KEY,
  	created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  	updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  	username VARCHAR(30) NOT NULL,
  	bio VARCHAR(400),
  	avatar VARCHAR(200),
  	phone VARCHAR(25),
  	email VARCHAR(40),
  	password VARCHAR(50),
  	status VARCHAR(15),
  	CHECK(COALESCE(phone, email) IS NOT NULL)
);

CREATE TABLE posts (
  	Id SERIAL PRIMARY KEY,
  	created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  	updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  	url VARCHAR(200) NOT NULL,
  	user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  	caption VARCHAR(240),
  	lat REAL CHECK(lat IS NULL OR (lat >= -90 AND lat <= 90)),
  	lng REAL CHECK(lng IS NULL OR (lng >= -180 AND lng <= 180))
);

CREATE TABLE comments (
  	id SERIAL PRIMARY KEY,
  	created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  	updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  	contents VARCHAR(240) NOT NULL,
  	user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  	post_id INTEGER NOT NULL REFERENCES posts(id) ON DELETE CASCADE
);

CREATE TABLE likes (
  	id SERIAL PRIMARY KEY,
  	created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  	user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  	comment_id INTEGER REFERENCES comments(id) ON DELETE CASCADE,
  	post_id INTEGER REFERENCES posts(id) ON DELETE CASCADE,
  	CHECK(COALESCE((comment_id)::BOOLEAN::INTEGER, 0) + COALESCE((post_id)::bOOLEAN::INTEGER, 0) = 1),
  	UNIQUE(user_id, post_id, comment_id)
);

CREATE TABLE photo_tags(
 	id SERIAL PRIMARY KEY,
  	created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  	updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  	post_id INTEGER NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  	user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  	x INTEGER NOT NULL,
  	y INTEGER NOT NULL,
  	UNIQUE(user_id, post_id)
);

CREATE TABLE caption_tags(
	id SERIAL PRIMARY KEY,
  	created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  	post_id INTEGER NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  	user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  	UNIQUE(user_id, post_id)
);

CREATE TABLE hashtags(
	id SERIAL PRIMARY KEY,
 	created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	title VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE hashtags_posts (	
	id SERIAL PRIMARY KEY,
	hashtag_id INTEGER NOT NULL REFERENCES hashtags(id) ON DELETE CASCADE,
	post_id INTEGER NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
	UNIQUE(hashtag_id, post_id)
);

CREATE TABLE followers(	id SERIAL PRIMARY KEY,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	leader_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	follower_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
 	UNIQUE(leader_id, follower_id)
);

-- -------------------------------------------------------------
CREATE INDEX ON likes (created_at);
EXPLAIN SELECT * FROM likes WHERE created_at < '2013-01-01';


WITH tags AS (
	SELECT user_id, created_at FROM caption_tags
	UNION ALL
	SELECT user_id, created_at FROM photo_tags
)
SELECT username, tags.created_at FROM users 
JOIN tags ON tags.user_id = users.id
WHERE tags.created_at < '2010-01-07';


WITH RECURSIVE suggestions(leader_id, follower_id, depth) AS (
	SELECT leader_id, follower_id, 1 AS depth FROM followers WHERE follower_id = 1000
UNION
	SELECT followers.leader_id, followers.follower_id, depth + 1 FROM followers
	JOIN suggestions ON suggestions.leader_id = followers.leader_id WHERE depth < 3
)
SELECT DISTINCT users.id, users.username FROM suggestions
JOIN users ON users.id = suggestions.leader_id WHERE depth > 1 LIMIT 5;


CREATE VIEW tags AS (
	SELECT id, created_at, user_id, 'photo_tag' AS type FROM photo_tags
	UNION ALL
	SELECT id, created_at, user_id, 'caption_tag' AS type FROM caption_tags
);

SELECT username, COUNT(*) FROM users JOIN tags ON tags.user_id = users.id
GROUP BY users.username 
ORDER BY COUNT(*) DESC
LIMIT 10;


CREATE VIEW recent_posts AS (
	SELECT * FROM posts ORDER BY created_at DESC LIMIT 10
);

SELECT username FROM recent_posts JOIN users ON users.id = recent_posts.user_id;
SELECT recent_posts.user_id, COUNT(*) FROM recent_posts JOIN likes ON likes.user_id = recent_posts.user_id
GROUP BY recent_posts.user_id;


CREATE MATERIALIZED VIEW weekly_likes AS(
	SELECT 
		date_trunc('week', COALESCE(posts.created_at, comments.created_at)) AS week,
		COUNT(posts.id) AS num_likes_for_posts,
		COUNT(comments.id) AS num_likes_for_comments
	FROM likes 
	LEFT JOIN posts ON posts.id = likes.post_id
	LEFT JOIN comments ON comments.id = likes.comment_id
	GROUP BY week
	ORDER BY week
) WITH DATA;

SELECT * FROM weekly_likes;

