# SQL Training

# Prerequisites

* git
* docker
* PostgreSQL client, one of:
  * DataGrip / IntelliJ
  * DBeaver
  * OmniDB
  * pgAdmin
  * SQL Workbench
  * PSequel
  
# Prepare DB

## Set up database

The easiest would be to run in docker container (no installation required, just pull and run) 

`docker run -d -p 15432:5432 -e POSTGRES_HOST_AUTH_METHOD=trust pdziok/sql-training`
