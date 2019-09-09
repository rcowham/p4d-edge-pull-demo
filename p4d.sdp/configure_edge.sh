#!/bin/bash
# Script which adjusts some edge server configurables for testing of pull-archive trigger.

. /p4/common/bin/p4_vars 1

/p4/common/bin/p4login

server_id=p4d_edge_bos

# Setup up key values for pull triggers.
# See: https://www.perforce.com/manuals/p4sag/Content/P4SAG/scripting.triggers.for-external-file-transfer.html

p4 --field Triggers+='pull_archive pull-archive pull "/p4/pull_test.sh %archiveList%"' triggers -o | p4 triggers -i
p4 --field Triggers+='EdgeSubmit edge-content //... "/p4/submit_test.sh  %changelist%"' triggers -o | p4 triggers -i

# Configure pull-archive usage
p4 configure set $server_id#pull.trigger.dir=/p4/1/tmp
p4 configure set $server_id#lbr.replica.notransfer=1
p4 configure set lbr.autocompress=1
# Configure submit content usage
p4 configure set $server_id#rpl.submit.nocopy=1

# Optional for edge server
p4 configure set $server_id#lbr.replication=cache
# Lots of logging!
p4 configure set rpl=4

# Configure our pull-archive trigger to be used, and for now unset the standard pull threads so they aren't used

p4 configure set "$server_id#startup.2=pull -i 1 -u --trigger --batch 2"
for i in {3..6}
do
    p4 configure unset "$server_id#startup.$i"
done

# Server requires restart to take account of changes to startup.N
p4 admin restart
