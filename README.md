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