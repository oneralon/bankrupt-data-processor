#!/bin/bash
cd "$BDP_BASE"
echo "$(date) Restart consumers" >> ../logs/cron.log
pkill nodemon
pkill phntomjs
sudo /etc/init.d/rabbitmq-server restart
grunt consumers:start