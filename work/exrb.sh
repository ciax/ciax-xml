#!/bin/bash
for file in ~/ciax-xml/*/*.rb; do
    $file
    [ $? = 1 ] && break
done
