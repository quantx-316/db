-- \COPY Users FROM './init/data/Users.csv' WITH DELIMITER ',' NULL '' CSV;
-- \COPY Quote FROM './init/data/Quotes.csv' WITH DELIMITER ',' NULL '' CSV;

\COPY Symbol FROM './init/data/Symbols.csv' WITH DELIMITER ',' NULL '' CSV; 
\COPY Quote FROM './init/data/1min/AAPL.csv' WITH DELIMITER ',' NULL '' CSV;
-- \COPY Users FROM './init/data/Users.csv' WITH DELIMITER ',' NULL '' CSV;
    