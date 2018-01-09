#!/bin/sh

while ( ! (find /var/log/azure/Microsoft.Azure.Diagnostics.LinuxDiagnostic/*/extension.log | xargs grep "Start mdsd"));
do
  echo "sleeping for 5"
  sleep 5 
done 

echo "updating apt pkgs"
sudo apt-get -y update 

echo "installing openjdk9"
sudo apt-get -y install openjdk-9-jre

echo "finished"