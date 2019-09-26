#!/bin/bash

# Requires docker-compose, curl and psql

FILE_DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" >& /dev/null && pwd)"
PROJECT_DIR=$FILE_DIR/..

NO_COLOUR='\033[0m'
RED='\033[1;31m'
GREEN='\033[1;32m'

run () {
  echo " |-> Running: '$1'"
  ip_address=$(eval $1 | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")

  if [ $? -eq 0 ]
  then
    echo -e "${GREEN} |-> Passed (with IP address: $ip_address) ${NO_COLOUR}"
  else
    echo -e "${RED} |-> Failed (no IP address found) ${NO_COLOUR}"
  fi
}


# -- TEST SETUP --
cd $PROJECT_DIR

echo "-> Starting up dcdc (assuming .bin/setup has ran)"
docker-compose build >& /dev/null
docker-compose up -d >& /dev/null

echo "-> Starting up proj1 web and db services"
cd $PROJECT_DIR/tests/example_projects/proj1
docker-compose build web db >& /dev/null
docker-compose up -d web db >& /dev/null

echo "-> Starting up proj2 web and db services"
cd $PROJECT_DIR/tests/example_projects/proj2
docker-compose build web db >& /dev/null
docker-compose up -d web db >& /dev/null

echo "-> Sleeping 10s while they start"
sleep 10

# -- TESTING ACCESS TO WEB SERVICE --

echo "-> Accessing proj1:web service (web.proj1.test) from external host (outside docker)"
run 'curl -s -L -k web.proj1.test'

echo "-> Accessing proj2:web service (web.proj2.test) from external host (outside docker)"
run 'curl -s -L -k web.proj2.test'

echo "-> Accessing proj1:web service (web.proj1.test) from proj2:runner container (inside docker)"
run 'docker-compose run runner curl -s -L -k web.proj1.test'

echo "-> Accessing proj2:web service (web.proj2.test) from proj2:runner container (inside docker)"
run 'docker-compose run runner curl -s -L -k web.proj2.test'

# -- TESTING ACCESS TO DB SERVICE --

echo "-> Accessing proj1:db service (db.proj1.test) from external host (outside docker)"
run 'PGPASSWORD=example psql -U postgres -h db.proj1.test -c "SELECT inet_server_addr();"'

echo "-> Accessing proj2:db service (db.proj2.test) from external host (outside docker)"
run 'PGPASSWORD=example psql -U postgres -h db.proj2.test -c "SELECT inet_server_addr();"'

echo "-> Accessing proj1:db service (db.proj1.test) from proj2:runner container (inside docker)"
run 'docker-compose run -e PGPASSWORD=example runner psql -U postgres -h db.proj1.test -c "SELECT inet_server_addr();"'

echo "-> Accessing proj2:db service (db.proj2.test) from proj2:runner container (inside docker)"
run 'docker-compose run -e PGPASSWORD=example runner psql -U postgres -h db.proj2.test -c "SELECT inet_server_addr();"'

# -- TEST TEARDOWN --

echo "-> Shutting down proj2 web and db services"
cd $PROJECT_DIR/tests/example_projects/proj2
docker-compose down >& /dev/null

echo "-> Shutting down proj1 web and db services"
cd $PROJECT_DIR/tests/example_projects/proj1
docker-compose down >& /dev/null

echo "-> Shutting down dcdc"
cd $PROJECT_DIR
docker-compose down >& /dev/null
