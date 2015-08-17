#!/bin/bash
cd "$BDP_BASE"
echo "$(date) Update meta info" >> ../logs/cron.log
grunt update:meta