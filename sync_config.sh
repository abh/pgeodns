#!/bin/sh
rsync --delete --exclude .svn --exclude *sample -a --port 7873 ddns1.develooper.com::dinamed-conf/ config/dist/

