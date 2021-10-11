#!/bin/bash 

docker build -t timedb . && docker run -d --name timedb -p 5432:5432 timedb