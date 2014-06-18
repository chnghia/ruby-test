# APP1

## Features

## Running

		> bundle install
		> rake run

## Running test

		> rake tests

## API

*Create a passenger record with phone number:*
  
  	$ curl -X PUT -d '{"phonenum": "0909123123"}' http://localhost:8001/passengers

*Retrieve a passenger:*
  
  	$ curl -X GET http://localhost:8001/passengers/0909123123

*Booking:*
  
  	$ curl -X PUT -d '{"phonenum": "0909123123", "password":"zt|pGvL", "lat": "10.7954196", "long":"106.6506274"}' http://localhost:8001/passengers/booking

