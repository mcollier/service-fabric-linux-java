#!/bin/sh

echo "installing packages"
until apt-get -y update && apt-get install -y openjdk-9-jre
do
echo "try again"
sleep 2
done