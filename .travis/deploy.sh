#!/bin/bash

# deploy from work directory
cd .travis/work

# get environment
printenv | sort | grep "^TRAVIS_" > environment.log

# get hercjsu summary
(cd prt; hercjsu *J????*.prt > ../hercjsu.log)

# setup list of files to deploy
echo "environment.log" > deploy.lst
echo "hercjsu.log" >> deploy.lst
find -regextype egrep -regex '.*/prt/.*\.prt' |\
     sort >> deploy.lst

# create tarball
tar -czf deploy.tgz -T deploy.lst

# upload
curl -w "status: %{http_code} send: %{size_upload} speed: %{speed_upload}\n" \
  -F 'trepo=mvs38j-langtest' \
  -F "tbldnum=$TRAVIS_BUILD_NUMBER" \
  -F "tjobnum=$TRAVIS_JOB_NUMBER"  \
  -F 'upfile=@deploy.tgz' \
  https://www.retro11.de/cgi-bin/upload_tdeploy.cgi > deploy.log
cat deploy.log
