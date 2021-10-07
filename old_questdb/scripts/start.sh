#!/bin/bash 

docker build -t timedb . && docker run -d --name timedb -p 9000:9000 -p 9009:9009 -p 8812:8812 -p 9003:9003 timedb