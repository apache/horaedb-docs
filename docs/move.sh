#!/bin/bash
echo "ready to move files"
cp -R ../i18n/cn ../html/cn
cp -R ../i18n/en ../html/en
cp -R ../../src/resources ../../book/html/resources
echo "copy done"
