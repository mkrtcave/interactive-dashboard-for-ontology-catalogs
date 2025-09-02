#!/bin/sh

echo "Waiting for GraphDB..."
sleep 10

curl -X POST http://graphdb:7200/rest/repositories \
  -H "Content-Type: multipart/form-data" \
  -F config=@/graphdb-init/repo-config.ttl

echo "Repository created."

curl -X POST http://graphdb:7200/rest/repositories \
  -H "Content-Type: multipart/form-data" \
  -F config=@/graphdb-init/repo-config-dashboard.ttl

echo "Repository created."