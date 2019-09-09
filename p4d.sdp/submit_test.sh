#!/bin/bash
#------------------------------------------------------------------------------
# Copyright and license info is available in the LICENSE file included with
# the Server Deployment Package (SDP), and also available online:
# https://swarm.workshop.perforce.com/projects/perforce-software-sdp/view/main/LICENSE
#------------------------------------------------------------------------------
# THIS IS A TEST SCRIPT - it substitutes for submit.sh which uses Aspera
# If you don't have an Aspera license, then you can test with this script
# to understand the process.
# IT IS NOT INTENDED FOR PRODUCTION USE!!!!
# -----------------------------------------------------------------------------
# 'fstat -Ob' with some filtering generates a list of files to be copied.
# Create a temp file with the filename pairs expected by ascp, and
# then perform the copy.
#
# This configurable must be set to force this submit trigger to be used:
# rpl.submit.nocopy=1
#
# The edge-content trigger looks like this:
#
#   EdgeSubmit edge-content //... "/p4/common/bin/triggers/test_submit.sh %changelist%"
#
# Assumes that scp is configured and that the standard OS user (e.g. perforce) can ssh
# without passwords between machines.
#
# Standard SDP environment is assumed, e.g P4USER, P4PORT, OSUSER, P4BIN, etc.
# are set, PATH is appropriate, and a super user is logged in with a non-expiring
# ticket.
#
# Standard SDP environment is assumed, e.g P4USER, P4PORT, OSUSER, P4BIN, etc.
# are set, PATH is appropriate, and a super user is logged in with a non-expiring
# ticket.

set -u

LOGFILE=$LOGS/submit.log

function msg () { echo -e "$*" >> $LOGFILE; echo -e "$*"; }
function bail () { msg "\nError: ${1:-Unknown Error}\n"; exit ${2:-1}; }

[[ $# -eq 1 ]] || bail "Bad Usage!\n\nUsage:\n\t$0 %changelist%\n\n"

change=$1

#------------------------------------------------------------------------------

declare tmpDir=$P4TMP
declare tmpFile="$tmpDir/tmpfile.$$.$RANDOM"
declare filelist="$tmpDir/filelist.$$.$RANDOM"
declare -i cnt=0

# Source SDP vars
source /p4/common/bin/p4_vars 1

date=$(date '+%Y-%m-%d %H:%M:%S')
echo "$date $filelist" >> $LOGFILE

if [[ ! -d "$tmpDir" ]]; then
   mkdir -p "$tmpDir" || bail "Failed to create temp dir [$tmpDir]."
fi

# Fstat all files in changelist which aren't lazy copies.
$P4BIN fstat -e $change -Rs -Ob -F lbrIsLazy=0 -T lbrPath @=$change | \
    grep "lbrPath" > $filelist 2>&1 ||\
    bail "$0: Non-zero exit code from fstat of change $change."

# Exit happily if the filelist file is empty, meaning there are no
# library files reported by the fstat to transfer for that change, e.g.
# if there are only lazy copies.
[[ ! -s $filelist ]] && exit 0

lines=$(cat $filelist | grep lbrPath | wc -l)
echo "File count $lines" >> $LOGFILE

while read file; do
   if [[ $file =~ lbrPath ]]; then
      file=${file##*\.\.\. lbrPath }
      echo "$file" >> $tmpFile
      # If using Aspera we would duplicate filenames - but for this script we don't have to
      # echo "$file" >> $tmpFile
      cnt+=1
   fi
done < $filelist

if [[ $cnt -eq 0 ]]; then
   exit 0
fi

# Record size summary
$P4BIN sizes -sh @=$change >> $LOGFILE

# Our Aspera substitute uses scp in a loop - not very efficient but it works for testing

while read file; do
    echo "$file" >> $LOGFILE
    # create directory if required for target - NOT EFFICIENT so use ssh like this!
    # Need to use ssh -n to avoid it reading stdin and causing our loop to exit early
    target_dir=$(dirname "$file")
    echo ssh -n "${OSUSER}@${P4MASTER}" mkdir -p "$target_dir" >> $LOGFILE
    ssh -n "${OSUSER}@${P4MASTER}" mkdir -p "$target_dir" >> $LOGFILE
    # Don't bother checking status of above command - any failures will be picked up
    # by scp below.
    echo scp "$file" "${OSUSER}@${P4MASTER}:$target_dir" >> $LOGFILE 2>&1
    scp "$file" "${OSUSER}@${P4MASTER}:$target_dir" >> $LOGFILE 2>&1
    if [[ $? -ne 0 ]]; then
        bail "$0: failed to scp $file, contact Perforce admin.\n"
    fi
done < $tmpFile

rm -f "$tmpFile"
rm -f "$filelist"

exit 0
