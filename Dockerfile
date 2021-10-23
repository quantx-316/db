FROM timescale/timescaledb:latest-pg12
ENV POSTGRES_USER root 
ENV POSTGRES_PASSWORD password 
ENV POSTGRES_DB quantx

COPY init/create.sql /docker-entrypoint-initdb.d/
COPY init/load.sql /docker-entrypoint-initdb.d/

COPY init/data/1min/AAPL.csv /docker-entrypoint-initdb.d/data/1min/AAPL.csv

COPY . .