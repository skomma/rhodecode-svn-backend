#!/bin/bash -eu
TARGET_FILE=$1

touch ${TARGET_FILE}
while inotifywait -e ATTRIB ${TARGET_FILE}; do
  apache2ctl graceful
done
