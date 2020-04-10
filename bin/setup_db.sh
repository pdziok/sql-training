#!/usr/bin/env bash

tempDir=$1
postgre_url='localhost:15432'
tempDir=$(mktemp -d /tmp/XXXXXXXXXXXXXXXXXXXX)
container=$(docker container ls -f ancestor=postgres -q)
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
schemaDir=$(echo "$(dirname $DIR)/schema")

echo "Copying schema files from $schemaDir"
docker cp $schemaDir $container:/var/lib/schema
echo "Creating matches table"
docker exec $container psql -U postgres -f "/var/lib/schema/atp_matches.sql"
echo "Creating players table"
docker exec $container psql -U postgres -f "/var/lib/schema/atp_players.sql"

echo "Cloning data source"
git clone --depth 1 -v git@github.com:JeffSackmann/tennis_atp.git $tempDir
echo "Fixing players dataset"
sed -i 's/0000,\([^,]*\)$/0101,\1/' $tempDir/atp_players.csv # will set birth date to 0101 instead of 0000 (MMDD)
sed -i 's/,\([0-9]\{6\}\),\([^,]*\)$/,\101,\2/' $tempDir/atp_players.csv # will set birth date to 0101 instead of 0000 (MMDD)
echo "Copying data from $tempDir"
docker cp $tempDir $container:/var/lib/data
12456
echo "Importing matches"
find $tempDir -regex '.*/atp_matches_[0-9]\{4\}.csv' -exec basename {} \; | xargs -I "{}" docker exec $container psql -U postgres -c "\copy atp_matches FROM '/var/lib/data/{}' DELIMITER ',' CSV HEADER"
echo "Importing players"
docker exec $container psql -U postgres -c "\copy atp_players FROM '/var/lib/data/atp_players.csv' DELIMITER ',' CSV"
#rm -rf $temp_dir