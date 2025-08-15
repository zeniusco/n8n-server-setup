#!/bin/bash
cd "$(dirname "$0")"
docker-compose pull n8n
docker-compose up -d n8n
