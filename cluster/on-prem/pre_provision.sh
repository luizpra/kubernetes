#!/bin/bash

echo "###################"


pwd
whoami
cat /etc/os-release

sleep 10

echo "Deleting old files!!!" 
rm admin.conf join-control-plane.sh join.sh
echo "Creating new kubernetes cluster ..."
sleep 3