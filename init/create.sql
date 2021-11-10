CREATE TABLE Users (
    id INT GENERATED ALWAYS AS IDENTITY, 
    username TEXT UNIQUE NOT NULL, 
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
    public BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY(id)
);

CREATE TABLE Backtest (
    id INT GENERATED ALWAYS AS IDENTITY, 
    algo INT REFERENCES Algorithm(id) ON DELETE CASCADE,
    owner INT REFERENCES Users(id) ON DELETE CASCADE,
    result TEXT, 
    score INT, 
    code_snapshot TEXT NOT NULL, 
    test_interval TEXT NOT NULL,
    test_start TIMESTAMP NOT NULL, 
    test_end TIMESTAMP NOT NULL, 
    created TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY(id)
);

/* 
    For ALL algorithms this table stores their associated best, latest backtest id. 
    This allows efficient querying of the form user --> public algos with user as owner --> best backtests
*/
CREATE TABLE BestAlgoBacktest (
    algo_id INT REFERENCES Algorithm(id) ON DELETE CASCADE, 
    backtest_id INT REFERENCES Backtest(id) ON DELETE CASCADE,
    PRIMARY KEY(algo_id)
);

/* 
    For ALL users WITH public algos. this table stores their best, latest backtest id with the extra cond. that the backtest's algorithm is 'public'.
    This allows efficient querying of a leaderboard based on user's best public algorithm performance. 
*/ 
CREATE TABLE BestUserBacktest (
    owner INT REFERENCES Users(id) ON DELETE CASCADE, 
    backtest_id INT REFERENCES Backtest(id) ON DELETE CASCADE,
    PRIMARY KEY(owner)
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

/* INDICES */
CREATE INDEX idx_algo_edited ON Algorithm(edited_at);

CREATE INDEX idx_algo_created ON Algorithm(created);

CREATE INDEX idx_backtest_score ON Backtest(score);
CREATE INDEX idx_backtest_test_start ON Backtest(test_start);
CREATE INDEX idx_backtest_test_end ON Backtest(test_end);
CREATE INDEX idx_backtest_created ON Backtest(created);

/* TRIGGERS */
    /* EDITED_AT for Algorithm auto-update */
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


/* Read comments in below similar trigger function for userback table */
CREATE OR REPLACE FUNCTION trigger_algoback_change()
RETURNS TRIGGER AS $$ 
BEGIN 
    IF (TG_OP = 'DELETE') THEN 
        IF NOT EXISTS(SELECT * FROM BestAlgoBacktest WHERE algo_id=OLD.algo) AND EXISTS(SELECT * FROM Backtest WHERE algo=OLD.algo) THEN 
            INSERT INTO BestAlgoBacktest VALUES (OLD.algo, (
                SELECT back.id FROM Backtest AS back 
                WHERE back.algo = OLD.algo AND back.score = (SELECT MAX(score) FROM Backtest WHERE algo = OLD.algo)
                ORDER BY back.created DESC 
                LIMIT 1 
            ));
        END IF; 
        return OLD; 
    END IF; 

    IF NEW.score IS NULL OR NEW.result IS NULL THEN 
        return NEW;
    END IF; 
    IF EXISTS(SELECT * FROM BestAlgoBacktest WHERE algo_id = NEW.algo) THEN 
        IF EXISTS(
            SELECT * FROM Backtest 
            WHERE ((NEW.score > score) OR (NEW.score = score AND NEW.created > created)) AND id=(
                SELECT backtest_id FROM BestAlgoBacktest WHERE algo_id=NEW.algo
            )
        ) THEN 
            UPDATE BestAlgoBacktest 
                SET backtest_id = NEW.id 
                WHERE algo_id = NEW.algo;
        END IF; 
    ELSE 
        INSERT INTO BestAlgoBacktest VALUES (NEW.algo, NEW.id);
    END IF; 
    return NEW; 
END; 
$$ LANGUAGE plpgsql;


CREATE TRIGGER on_algoback_change 
AFTER INSERT OR UPDATE OR DELETE ON Backtest 
FOR EACH ROW 
EXECUTE PROCEDURE trigger_algoback_change();



CREATE OR REPLACE FUNCTION trigger_userback_change() 
RETURNS TRIGGER AS $$ 
BEGIN 
    IF (TG_OP = 'DELETE') THEN 

        /* 
            Check if algorithm associated with this backtest is even public 
        */
        IF NOT EXISTS(SELECT * FROM Algorithm WHERE id = OLD.algo AND public = TRUE) THEN 
            return OLD; 
        END IF; 

        /* 
            After deletion
            - check if the deletion of this backtest resulted in a removal from BestUserBacktest (ie this backtest was the best one)
            - check if there are even any more backtests associated with the owner 

            If so, then insert the best backtest associated with owner into table 
         */
        IF NOT EXISTS(SELECT * FROM BestUserBacktest WHERE owner=OLD.owner) AND EXISTS(SELECT * FROM Backtest WHERE owner=OLD.owner) THEN 
            INSERT INTO BestUserBacktest VALUES (OLD.owner, (
                SELECT back.id FROM Backtest AS back JOIN Algorithm AS algo ON algo.id = back.algo 
                WHERE algo.public = TRUE AND back.owner = OLD.owner AND back.score = (
                    SELECT MAX(score) FROM Backtest AS back2 JOIN Algorithm AS algo2 ON algo2.id = back2.algo WHERE algo2.public = TRUE AND back2.owner = OLD.owner
                )
                ORDER BY back.created DESC 
                LIMIT 1 
            ));
        END IF; 

        return OLD; 
    END IF; 


    /* 
        Check if algorithm associated with this backtest is even public 
    */
    IF NOT EXISTS(SELECT * FROM Algorithm WHERE id = NEW.algo AND public = TRUE) THEN 
        return NEW; 
    END IF; 

    /* 
        Check if backtest is ready (if not, it'll trigger on next update when its results are ready)
    */
    IF NEW.score IS NULL OR NEW.result IS NULL THEN 
        return NEW;
    END IF; 

    /* 
        If no entry existing with associated owner, then just insert 
        Otherwise we use exists(...) to efficiently check that either our new backtest score or its created date (if score is equal) 
        is greater than the current existing entry 
    */
    IF EXISTS(SELECT * FROM BestUserBacktest WHERE owner = NEW.owner) THEN 
        IF EXISTS(
            SELECT * FROM Backtest 
            WHERE ((NEW.score > score) OR (NEW.score = score AND NEW.created > created)) AND id=(
                SELECT backtest_id FROM BestUserBacktest WHERE owner = NEW.owner 
            )
        ) THEN 
            UPDATE BestUserBacktest 
                SET backtest_id = NEW.id 
                WHERE owner = NEW.owner;
        END IF; 
    ELSE 
        INSERT INTO BestUserBacktest VALUES (NEW.owner, NEW.id);
    END IF; 
    return NEW; 
END; 
$$ LANGUAGE plpgsql;


CREATE TRIGGER on_userback_change 
AFTER INSERT OR UPDATE OR DELETE ON Backtest 
FOR EACH ROW
EXECUTE PROCEDURE trigger_userback_change();


CREATE FUNCTION recalc_userback_insert(queryowner int) 
RETURNS void AS $$ 
BEGIN 
    INSERT INTO BestUserBacktest VALUES (queryowner, (
        SELECT back.id 
        FROM Algorithm AS algo JOIN Backtest AS back ON algo.id = back.algo 
        WHERE algo.public = TRUE AND back.score = (
            SELECT MAX(back2.score) FROM Algorithm AS algo2 JOIN Backtest AS back2 ON algo2.id = back2.algo 
            WHERE algo2.public = TRUE AND algo2.owner = queryowner 
        )
        ORDER BY back.created DESC 
        LIMIT 1 
    ));
END; 
$$ LANGUAGE plpgsql; 

CREATE FUNCTION recalc_userback_update(queryowner int) 
RETURNS void as $$ 
BEGIN 
    UPDATE BestUserBacktest 
        SET backtest_id = (
            SELECT back.id 
            FROM Algorithm AS algo JOIN Backtest AS back ON algo.id = back.algo 
            WHERE algo.public = TRUE AND back.score = (
                SELECT MAX(back2.score) FROM Algorithm AS algo2 JOIN Backtest AS back2 ON algo2.id = back2.algo 
                WHERE algo2.public = TRUE AND algo2.owner = queryowner 
            )
            ORDER BY back.created DESC 
            LIMIT 1 
        )
        WHERE owner = queryowner;
END; 
$$ LANGUAGE plpgsql; 


/* 
    This serves a different purpose than the trigger above. 
    Since the userback table has the extra caveat that the backtest must be public, we do test in the backtest
    table whether the given backtest has a public algorithm, BUT a user may decide to make an algorithm private,
    in which case the table does not match its constraints now.

    So this function and its trigger is meant to recalculate the best backtest in the scenario that an algorithm 
    is made public/private, since in either case the best backtest may change. 
*/
CREATE OR REPLACE FUNCTION trigger_userback_algo_change()
RETURNS TRIGGER AS $$ 
BEGIN     
    /* Check if old.public is diff from new.public */
    IF (OLD.public = NEW.public) THEN 
        RETURN NEW; 
    END IF; 

    IF (NEW.public) THEN 
        IF EXISTS(SELECT * FROM BestUserBacktest WHERE owner=NEW.owner) THEN 
            PERFORM recalc_userback_update(NEW.owner);
        ELSE 
            PERFORM recalc_userback_insert(NEW.owner);
        END IF; 
    ELSE
        IF EXISTS(SELECT * FROM Algorithm WHERE id=NEW.id AND owner = NEW.owner) THEN 
            IF (NEW.id = (
                SELECT algo.id FROM Algorithm AS algo JOIN Backtest AS back ON algo.id = back.algo
                WHERE back.id = (SELECT backtest_id FROM BestUserBacktest WHERE owner = NEW.owner)
            )) THEN 
                IF EXISTS(SELECT * FROM BestUserBacktest WHERE owner = NEW.owner) THEN 
                    PERFORM recalc_userback_update(NEW.owner);
                ELSE 
                    PERFORM recalc_userback_insert(NEW.owner);
                END IF; 
            END IF; 
        ELSE 
            IF EXISTS(SELECT * FROM BestUserBacktest WHERE owner = NEW.owner) THEN 
                DELETE FROM BestUserBacktest WHERE owner = NEW.owner; 
            END IF; 
        END IF; 
    END IF; 
    RETURN NEW; 
END; 
$$ LANGUAGE plpgsql;


CREATE TRIGGER on_userback_algo_change 
AFTER UPDATE ON Algorithm 
FOR EACH ROW 
EXECUTE PROCEDURE trigger_userback_algo_change();


/* Quotes */

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
CREATE MATERIALIZED VIEW Quote_1m 
WITH (timescaledb.continuous) AS
SELECT time_bucket(INTERVAL '1 minute', Quote.time) AS candle,
       symbol,
       first(price_open, Quote.time) AS price_open,
       max(price_high) AS price_high,
       min(price_low) AS price_low,
       last(price_close, Quote.time) AS price_close
FROM Quote 
GROUP BY symbol, candle;

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
