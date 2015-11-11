#!/bin/bash

# We first create the new packaged database
RAILS_ENV=production bundle exec rake fdb:package

DESTINATION="$1"

# We now transfer the timestamped database(s) to the backup server
# This support multiple databases (in case a previous transfer failed)
for db in db/package/*.sqlite3; do
  # We don't touch the current snapshot that is offered through the API
  if ! [ "$db" == "db/package/packaged.sqlite3" ] ; then
    echo "Backing up $db to $DESTINATION"
    scp $db $DESTINATION

    # We make sure it worked
    if [ $? -eq 0 ]; then
      echo "Backup of $db succeeded, deleting it from this server..."
      # In the event it tries to delete multiple files, this will stop it
      rm -I $db
    else
      echo "Backup of $db to $DESTINATION failed. Keeping local copy..."
    fi
  fi
done
