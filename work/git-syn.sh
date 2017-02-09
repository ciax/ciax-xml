#!/bin/bash
git checkout develop
git pull
for i; do
    git checkout $i
    git pull
    git merge develop
    git push
    git checkout develop 
done
