#!/bin/bash
echo "Removing old build"
rm -r public
rm -r /var/www/btapes/* 
echo "Publishing webiste"
hugo
cp -r public/* /var/www/btapes
echo "Website deployed"


