## db

* On a high-level is just TimescaleDB and its associated setup



### Structure

* /app/init
  * create.sql and load.sql are loaded into setup by the Dockerfile and are automatically executed at db setup	
    * create.sql 
      * contains entire db structure, including tables, indices, triggers, ...
    * load.sql 
      * primarily loads stock and quotes information, see real_stress_generate.py mentioned in server repository README.md for comprehensive data generation
* /app/ingest 
  * contains scripts for continuous quote ingestion into databased



## Development

* Read through https://docs.timescale.com/
* Recommendation is to run as entire stack as in top-level repository README.md
