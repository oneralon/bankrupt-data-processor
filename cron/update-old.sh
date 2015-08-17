#!/bin/bash
cd "$BDP_BASE"
echo "$(date) Start updating old" >> logs/cron.log
grunt update:old