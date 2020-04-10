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

## Docker

The easiest would be to run in docker container (no installation required, just pull and run) 

`docker pull postgres`

Then run (for the purpose of this training):

`docker run -d -p 15432:5432 -e POSTGRES_HOST_AUTH_METHOD=trust postgres`

## Self installed

You can install using brew:

`brew install postgresql`

# Load data

Run:

`./bin/setup_db.sh`

