#!/bin/bash

# the url always change it so we find it though the page
ANDROID_PDF=$(curl https://support.google.com/googleplay/answer/1727131?hl=en-CA | egrep -o "//storage.googleapis.com/support-kms-prod/.*\">PDF" | egrep -o //storage.googleapis.com/support-kms-prod/.*\" | sed -e 's/\"//')
ANDROID_PDF="https:$ANDROID_PDF"
echo $ANDROID_PDF

# get the android models pdf and convert it
curl $ANDROID_PDF > tmp/android_devices.pdf
pdftotext -layout tmp/android_devices.pdf

# we launch the importation job
echo "Starting Android import job"
RAILS_ENV=production bundle exec rake import:android_models[tmp/android_devices.txt]

# refresh cfnetwork discoverers
curl http://user-agents.me/cfnetwork-version-list > tmp/cfnetwork-version-list.html
# we discover the cfnetwork
echo "Starting CFNETWORK import job"
RAILS_ENV=production bundle exec rake import:cfnetwork[tmp/cfnetwork-version-list.html]

curl http://standards-oui.ieee.org/oui.txt > tmp/oui.txt
RAILS_ENV=production bundle exec rake import:mac_vendors_from_oui_file[tmp/oui.txt]

# discovery jobs
echo "Starting Windows phone discovery job"
RAILS_ENV=production bundle exec rake import:discover_windows_phone
echo "Starting BB phone discovery job"
RAILS_ENV=production bundle exec rake import:discover_blackberry_models

# p0f map generation
RAILS_ENV=production bundle exec rake tcp:generate_p0f_map

# merge the stats that were collected (2 days worth)
#echo "Starting merge with stats"
#RAILS_ENV=production bundle exec rake import:merge_stats[tmp/stats.sqlite,2]

## remove the orphan data due to administrative deletion or another reason
#RAILS_ENV=production bundle exec rake clean:delete_orphans

## delete user agents which we have no chances to detect
#RAILS_ENV=production bundle exec rake clean:delete_lost_causes

## delete invalid combinations
#RAILS_ENV=production bundle exec rake fdb:delete_invalid_combinations

# rebuild the discoverers cache from scratch
echo "Starting discoverers cache build"
RAILS_ENV=production bundle exec rake fbcache:build_discoverers 

# reevaluate every combination
echo "Starting the reprocessing of all the combinations"
RAILS_ENV=production bundle exec rake fdb:process_combination

# find the mobile + tablets in what we have
echo "Finding the mobiles + tablets"
RAILS_ENV=production bundle exec rake import:detect_device_metadata

# refresh the stats page on the website
echo "Refreshing the stats"
RAILS_ENV=production bundle exec rake fbcache:refresh_stats

# generate the daily report that goes in the event log
echo "Generating the daily report"
RAILS_ENV=production bundle exec rake report:generate_in_events

touch tmp/restart.txt
