#!/bin/sh

echo "Deleting daily files older than 31 days"

find ./om-gta02-unstable/deploy/glibc/images -mtime +30 -print -delete
find ./om-gta02-experimental/deploy/glibc/images -mtime +30 -print -delete