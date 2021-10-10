CREATE TABLE Users (
    id INT GENERATED BY DEFAULT AS IDENTITY, 
    email TEXT UNIQUE NOT NULL, 
    hashed_password TEXT NOT NULL,
    firstname VARCHAR(255), 
    lastname VARCHAR(255),
    description TEXT,
    PRIMARY KEY(id)
);

CREATE TABLE Strategy (
    id INT GENERATED BY DEFAULT AS IDENTITY, 
    uid INT REFERENCES Users(id),
    code TEXT NOT NULL,
    PRIMARY KEY(id)
);

CREATE TABLE Backtest (
    id INT GENERATED BY DEFAULT AS IDENTITY, 
    result TEXT, 
    code_snapshot TEXT NOT NULL, 
    test_start TIMESTAMP NOT NULL, 
    test_end TIMESTAMP NOT NULL, 
    created TIMESTAMP NOT NULL,
    PRIMARY KEY(id)
);

CREATE TABLE Competition (
    id INT GENERATED BY DEFAULT AS IDENTITY, 
    title TEXT NOT NULL, 
    description TEXT NOT NULL, 
    owner INT REFERENCES Users(id),
    created TIMESTAMP NOT NULL, 
    end_time TIMESTAMP NOT NULL, 
    test_start TIMESTAMP NOT NULL, 
    test_end TIMESTAMP NOT NULL,
    PRIMARY KEY(id)
);

CREATE TABLE CompetitionEnrollment (
    comp_id INT REFERENCES Competition(id),
    uid INT REFERENCES Users(id),
    PRIMARY KEY(uid, comp_id)
);

CREATE TABLE CompetitionEntry (
    comp_id INT REFERENCES Competition(id),
    backtest_id INT REFERENCES Backtest(id),
    PRIMARY KEY(comp_id, backtest_id)
);

CREATE TABLE Symbol (
    symbol TEXT NOT NULL PRIMARY KEY, 
    name TEXT NOT NULL,
    description TEXT
);

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
