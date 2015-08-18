# Bankrupt Data Processor

## 1. Installation
1.1 Install AMQP-server and redis
```
# apt-get install rabbitmq-server redis-server
```
1.2 Enable RabbitMQ managment plugin
```
# rabbitmq-plugins enable rabbitmq_management
```
1.3 Install MongoDB
```
# apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
# echo "deb http://repo.mongodb.org/apt/debian wheezy/mongodb-org/3.0 main" | \
       tee /etc/apt/sources.list.d/mongodb-org-3.0.list
# apt-get update
# apt-get install -y mongodb-org
```
1.4 Install global NPM-packages
```
# npm install -g phantomjs forever coffee-script grunt-cli nodemon
```
1.5 Install local NPM-packages
```
$ npm install
```
1.6 Add env variable
```
$ echo "export $BDP_BASE=$(pwd)" >> ~/.bashrc
```
1.7 Allow restart rabbit
```
# echo "%sudo ALL=NOPASSWD: /etc/init.d/rabbitmq-server" >> /etc/sudoers
```

## 2. Using
2.1 Full collect from all ETPs
```
$ grunt collect:full
```
2.2 New collect from all ETPs
```
$ grunt collect:update
```
2.3 Start consumers
```
$ grunt consumers:start
```
2.4 Delete dublicates of trades
```
$ grunt migration:dublicates
```
2.5 Select chank of invalid trades for update
```
$ grunt update:invalid
```
2.6 Select chank of invalid trades for update
```
$ grunt update:old
```
2.7 Update meta info (after all)
```
$ grunt update:meta
```