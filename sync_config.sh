#!/bin/sh
rsync --delete --exclude .svn --exclude *sample -a --port 7873 ddns1.develooper.com::dinamed-conf/ config/dist/


# run this from crontab with something like 
#   */3 * * * * sleep $(expr $RANDOM \% 60); cd /var/services/pgeodns/pgeodns; ./sync_config.sh 
# 
