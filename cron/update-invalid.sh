#!/bin/bash
cd "$BDP_BASE"
echo "$(date) Start updating invalid" >> logs/cron.log
grunt update:invalid