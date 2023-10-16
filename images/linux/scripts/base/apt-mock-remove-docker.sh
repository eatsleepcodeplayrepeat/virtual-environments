#!/bin/bash -e

prefix=/usr/local/bin

for tool in apt apt-get apt-fast apt-key;do
  rm -f $prefix/$tool
done
