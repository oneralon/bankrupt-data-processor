#!/bin/bash
cd "$BDP_BASE"
echo "$(date) Start events migration" >> logs/cron.log
grunt migration:events