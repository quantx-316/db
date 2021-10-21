#!/bin/bash 

psql -af ./init/create.sql quantx 
psql -af ./init/load.sql quantx 