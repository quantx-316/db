FROM timescale/timescaledb:latest-pg12
ENV POSTGRES_USER root 
ENV POSTGRES_PASSWORD password 
ENV POSTGRES_DB quantx

COPY init/create.sql /docker-entrypoint-initdb.d/
COPY init/load.sql /docker-entrypoint-initdb.d/

COPY init/data/1min/AAPL.csv /docker-entrypoint-initdb.d/data/1min/AAPL.csv
COPY init/data/Symbols.csv /docker-entrypoint-initdb.d/data/Symbols.csv
COPY init/data/Users.csv /docker-entrypoint-initdb.d/data/Users.csv

COPY . .