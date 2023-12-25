#!/usr/bin/env bash

set -exo

cd $( dirname ${0} ) >/dev/null 2>&1

echo "Moving files ..."

cp -R book/i18n/cn book/html/cn
cp -R book/i18n/en book/html/en
cp -R resources book/html/resources

cp ../.asf.yaml book/html/.asf.yaml

echo "Files has been moved."
