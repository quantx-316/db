CREATE TABLE Users (
    id INT GENERATED ALWAYS AS IDENTITY, 
    email TEXT UNIQUE NOT NULL, 
    hashed_password TEXT NOT NULL,
    firstname VARCHAR(255), 
    lastname VARCHAR(255),
    description TEXT,
    PRIMARY KEY(id)
);

CREATE TABLE Algorithm (
    id INT GENERATED ALWAYS AS IDENTITY, 
    owner INT REFERENCES Users(id) ON DELETE CASCADE,
    title TEXT NOT NULL, 
    code TEXT NOT NULL,
    created TIMESTAMP NOT NULL DEFAULT NOW(), 
    edited_at TIMESTAMP NOT NULL DEFAULT NOW(), 
    PRIMARY KEY(id)
);

CREATE TABLE Backtest (
    id INT GENERATED ALWAYS AS IDENTITY, 
    owner INT REFERENCES Users(id) ON DELETE CASCADE,
    result TEXT, 
    code_snapshot TEXT NOT NULL, 
    test_start TIMESTAMP NOT NULL, 
    test_end TIMESTAMP NOT NULL, 
    created TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY(id)
);

CREATE TABLE Competition (
    id INT GENERATED ALWAYS AS IDENTITY, 
    title TEXT NOT NULL, 
    description TEXT NOT NULL, 
    owner INT REFERENCES Users(id) ON DELETE SET NULL,
    created TIMESTAMP NOT NULL DEFAULT NOW(), 
    end_time TIMESTAMP NOT NULL, 
    test_start TIMESTAMP NOT NULL, 
    test_end TIMESTAMP NOT NULL,
    PRIMARY KEY(id)
);

CREATE TABLE CompetitionEnrollment (
    comp_id INT REFERENCES Competition(id) ON DELETE CASCADE,
    uid INT REFERENCES Users(id) ON DELETE CASCADE,
    PRIMARY KEY(uid, comp_id)
);

CREATE TABLE CompetitionEntry (
    comp_id INT REFERENCES Competition(id) ON DELETE CASCADE,
    backtest_id INT REFERENCES Backtest(id) ON DELETE CASCADE,
    submitted TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY(comp_id, backtest_id)
);

CREATE TABLE Symbol (
    symbol TEXT NOT NULL PRIMARY KEY, 
    name TEXT NOT NULL,
    description TEXT
);

/* TRIGGERS */
CREATE OR REPLACE FUNCTION trigger_update_edited_at() 
RETURNS TRIGGER AS $$ 
BEGIN 
    NEW.edited_at = NOW();
    RETURN NEW; 
END; 
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_algo_edited_at 
BEFORE UPDATE ON Algorithm
FOR EACH ROW 
EXECUTE PROCEDURE trigger_update_edited_at();

CREATE TABLE Quote (
    time TIMESTAMP NOT NULL, 
    symbol TEXT REFERENCES Symbol(symbol),
    price_open DOUBLE PRECISION NULL,
    price_high DOUBLE PRECISION NULL,
    price_low DOUBLE PRECISION NULL,
    price_close DOUBLE PRECISION NULL,

    PRIMARY KEY (symbol, time)
);

CREATE EXTENSION IF NOT EXISTS timescaledb;

/* Create hypertable from Quotes table */ 
SELECT create_hypertable('Quote', 'time');

/* Continuous aggregate views for different time intervals */
CREATE MATERIALIZED VIEW Quote_5m 
WITH (timescaledb.continuous) AS 
SELECT time_bucket(INTERVAL '5 minutes', Quote.time) AS candle,
       symbol,
       first(price_open, Quote.time) AS price_open,
       max(price_high) AS price_high,
       min(price_low) AS price_low,
       last(price_close, Quote.time) AS price_close
FROM Quote 
GROUP BY symbol, candle;

CREATE MATERIALIZED VIEW Quote_15m 
WITH (timescaledb.continuous) AS 
SELECT time_bucket(INTERVAL '15 minutes', Quote.time) AS candle,
       symbol,
       first(price_open, Quote.time) AS price_open,
       max(price_high) AS price_high,
       min(price_low) AS price_low,
       last(price_close, Quote.time) AS price_close
FROM Quote 
GROUP BY symbol, candle;

CREATE MATERIALIZED VIEW Quote_30m 
WITH (timescaledb.continuous) AS 
SELECT time_bucket(INTERVAL '30 minutes', Quote.time) AS candle,
       symbol,
       first(price_open, Quote.time) AS price_open,
       max(price_high) AS price_high,
       min(price_low) AS price_low,
       last(price_close, Quote.time) AS price_close
FROM Quote 
GROUP BY symbol, candle;

CREATE MATERIALIZED VIEW Quote_1h 
WITH (timescaledb.continuous) AS 
SELECT time_bucket(INTERVAL '1 hour', Quote.time) AS candle,
       symbol,
       first(price_open, Quote.time) AS price_open,
       max(price_high) AS price_high,
       min(price_low) AS price_low,
       last(price_close, Quote.time) AS price_close
FROM Quote 
GROUP BY symbol, candle;

CREATE MATERIALIZED VIEW Quote_1d
WITH (timescaledb.continuous) AS 
SELECT time_bucket(INTERVAL '1 day', Quote.time) AS candle,
       symbol,
       first(price_open, Quote.time) AS price_open,
       max(price_high) AS price_high,
       min(price_low) AS price_low,
       last(price_close, Quote.time) AS price_close
FROM Quote 
GROUP BY symbol, candle;

CREATE MATERIALIZED VIEW Quote_1w
WITH (timescaledb.continuous) AS 
SELECT time_bucket(INTERVAL '1 week', Quote.time) AS candle,
       symbol,
       first(price_open, Quote.time) AS price_open,
       max(price_high) AS price_high,
       min(price_low) AS price_low,
       last(price_close, Quote.time) AS price_close
FROM Quote 
GROUP BY symbol, candle;
