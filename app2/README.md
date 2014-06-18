# APP2

## Features

## Running

Start up Redis:
> service redis-server start

Start Sidekiq
> rake sidekiq

Start Application
> bundle install
> rake run

## Running test

> rake tests

## API

*Retrieve all drivers with location*
  $ curl -X GET http://localhost:8002/drivers

*Retrieve all driver with location*
  $ curl -X GET http://localhost:8002/drivers/1

*Assign nearest driver with latitute/longitude, with asynchronous send text message:*
  $ curl -X PUT -d '{"lat":"10.7954196", "long":"106.6506274"}' http://localhost:8002/drivers/nearest