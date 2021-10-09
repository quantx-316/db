\COPY Users FROM './init/data/Users.csv' WITH DELIMITER ',' NULL '' CSV;
\COPY Symbol FROM './init/data/Symbols.csv' WITH DELIMITER ',' NULL '' CSV; 
\COPY Quote FROM './init/data/Quotes.csv' WITH DELIMITER ',' NULL '' CSV;
\COPY Profile FROM './init/data/Profiles.csv' WITH DELIMITER ',' NULL '' CSV;