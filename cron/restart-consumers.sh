#!/bin/bash
cd "$BDP_BASE"
echo "$(date) Restart consumers" >> logs/cron.log
sudo /etc/init.d/rabbitmq-server restart
sleep(1)
pkill nodemon
pkill phntomjs
grunt consumers:start