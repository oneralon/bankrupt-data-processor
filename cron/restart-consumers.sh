#!/bin/bash
cd "$BDP_BASE"
echo "$(date) Restart consumers" >> logs/cron.log
sudo /etc/init.d/rabbitmq-server restart
sleep 2
pkill -9 -f 'node /usr/local/bin/coffee consumers/lists-html.coffee'
pkill -9 -f 'node /usr/local/bin/coffee consumers/trades-html.coffee'
pkill -9 -f 'node /usr/local/bin/coffee consumers/trades-json.coffee'
pkill -9 -f 'node /usr/local/bin/coffee consumers/trades-url.coffee'
pkill -9 -f 'node /usr/local/bin/coffee consumers/lots-url.coffee'
pkill -9 -f 'node /usr/local/bin/coffee consumers/lots-html.coffee'
pkill -9 -f 'node /usr/local/bin/coffee consumers/lots-json.coffee'
pkill phntomjs
grunt consumers:start