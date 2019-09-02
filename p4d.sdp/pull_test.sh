#!/bin/bash
#------------------------------------------------------------------------------
# Copyright and license info is available in the LICENSE file included with
# the Server Deployment Package (SDP), and also available online:
# https://swarm.workshop.perforce.com/projects/perforce-software-sdp/view/main/LICENSE
#------------------------------------------------------------------------------
# THIS IS A TEST SCRIPT - it substitutes for pull.sh which uses Aspera
# If you don't have an Aspera license, then you can test with this script
# to understand the process.
# IT IS NOT INTENDED FOR PRODUCTION USE!!!!
# -----------------------------------------------------------------------------
# Read filename to get list of files to copy from commit to edge.
# Do the copy using scp (instead of Aspera ascp)
#
# configurable pull.trigger.dir should be set to a temp folder like /p4/1/tmp
#
# Startup commands look like:
# startup.2=pull -i 1 -u --trigger --batch=1000
#
# The trigger entry for the pull commands looks like this:
#
#   pull_archive pull-archive pull "/p4/common/bin/triggers/pull_test.sh %archiveList%"
#
# Assumes that scp is configured and that the standard OS user (e.g. perforce) can ssh
# without passwords between machines.
#
# Standard SDP environment is assumed, e.g P4USER, P4PORT, OSUSER, P4BIN, etc.
# are set, PATH is appropriate, and a super user is logged in with a non-expiring
# ticket.

set -u

function msg () { echo -e "$*"; }
function bail () { msg "\nError: ${1:-Unknown Error}\n"; exit ${2:-1}; }

[[ $# -eq 1 ]] || bail "Bad Usage!\n\nUsage:\n\t$0 %archiveList%\n\n"

. /p4/common/bin/p4_vars 1

LOGFILE=$LOGS/pull.log
filelist=$1

date=$(date '+%Y-%m-%d %H:%M:%S')
echo "$date $filelist" >> $LOGFILE
lines=$(cat $filelist | wc -l)
echo "File count $(($lines / 2))" >> $LOGFILE 

[[ -f $filelist ]] || { echo "$filelist missing!" >> $LOGFILE; exit 1; }

# Extract every second line, create directory if required for target and copy file
cat $filelist | awk 'NR%2' | while read f
do
    echo "$f" >> $LOGFILE
    target_dir=$(dirname "$f")
    mkdir -p "$target_dir"
    scp "${OSUSER}@${P4MASTER}:$f" "$target_dir" >> $LOGFILE 2>&1
    if [[ $? -ne 0 ]]; then
        bail "$0: failed to scp $f, contact Perforce admin.\n"
    fi
done

exit 0
