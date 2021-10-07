CREATE TABLE IF NOT EXISTS trades (ts TIMESTAMP, date DATE, name STRING, value INT) timestamp(ts);

CREATE TABLE IF NOT EXISTS users(name STRING, value INT);

SELECT * FROM trades;
SELECT * FROM users;

INSERT INTO users 
VALUES('abc', 123456); 