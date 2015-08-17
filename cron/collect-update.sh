#!/bin/bash
cd "$BDP_BASE"
echo "$(date) Start updating from sources" >> logs/cron.log
grunt collect:update