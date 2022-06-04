#!/bin/bash
# $Id: deploy.sh 1240 2022-05-22 13:57:50Z mueller $
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright 2022- by Walter F.J. Mueller <W.F.J.Mueller@gsi.de>

# deploy from work directory
cd .github/work

# get environment
printenv | sort | grep "^GITHUB_" > environment.log

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
  -F 'repo=mvs38j-langtest' \
  -F "runnum=$GITHUB_RUN_NUMBER" \
  -F "jobid=$JOBID"  \
  -F 'upfile=@deploy.tgz' \
  https://www.retro11.de/cgi-bin/upload_adeploy.cgi > deploy.log
cat deploy.log
