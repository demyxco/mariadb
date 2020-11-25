#!/bin/bash
# Demyx
# https://demyx.sh

# Get versions
DEMYX_MARIADB_ALPINE_VERSION="$(/usr/bin/docker exec "$DEMYX_REPOSITORY" /bin/cat /etc/os-release | /bin/grep VERSION_ID | /usr/bin/cut -c 12- | /bin/sed 's/\r//g')"
DEMYX_MARIADB_VERSION="$(/usr/bin/docker exec "$DEMYX_REPOSITORY" /usr/bin/mysql --version | awk -F '[ ]' '{print $6}' | awk -F '[,]' '{print $1}' | /bin/sed 's/-MariaDB//g' | /bin/sed 's/\r//g')"

# Replace versions
/bin/sed -i "s|alpine-.*.-informational|alpine-${DEMYX_MARIADB_ALPINE_VERSION}-informational|g" README.md
/bin/sed -i "s|${DEMYX_REPOSITORY}-.*.-informational|${DEMYX_REPOSITORY}-${DEMYX_MARIADB_VERSION}-informational|g" README.md

# Echo versions to file
/bin/echo "DEMYX_MARIADB_ALPINE_VERSION=$DEMYX_MARIADB_ALPINE_VERSION
DEMYX_MARIADB_VERSION=$DEMYX_MARIADB_VERSION" > VERSION

# Push back to GitHub
git config --global user.email "travis@travis-ci.com"
git config --global user.name "Travis CI"
git remote set-url origin https://"$DEMYX_GITHUB_TOKEN"@github.com/demyxco/"$DEMYX_REPOSITORY".git
# Commit VERSION first
git add VERSION
git commit -m "ALPINE $DEMYX_MARIADB_ALPINE_VERSION, MARIADB $DEMYX_MARIADB_VERSION"
git push origin HEAD:master
# Commit the rest
git add .
git commit -m "Travis Build $TRAVIS_BUILD_NUMBER"
git push origin HEAD:master

# Send a PATCH request to update the description of the repository
/bin/echo "Sending PATCH request"
DEMYX_DOCKER_TOKEN="$(/usr/bin/curl -s -H "Content-Type: application/json" -X POST -d '{"username": "'"$DEMYX_USERNAME"'", "password": "'"$DEMYX_PASSWORD"'"}' "https://hub.docker.com/v2/users/login/" | /usr/local/bin/jq -r .token)"
DEMYX_RESPONSE_CODE="$(/usr/bin/curl -s --write-out "%{response_code}" --output /dev/null -H "Authorization: JWT ${DEMYX_DOCKER_TOKEN}" -X PATCH --data-urlencode full_description@"README.md" "https://hub.docker.com/v2/repositories/${DEMYX_USERNAME}/${DEMYX_REPOSITORY}/")"
/bin/echo "Received response code: $DEMYX_RESPONSE_CODE"

# Return an exit 1 code if response isn't 200
[[ "$DEMYX_RESPONSE_CODE" != 200 ]] && exit 1
