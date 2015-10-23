#!/bin/bash
cd "$BDP_BASE"
echo "$(date) Remove not existing lots" >> logs/cron.log
grunt migration:existing
