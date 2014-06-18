ENV['RACK_ENV'] = 'test'


# SimpleCov must be loaded before the Sinatra DSL
# and the application code.
require 'simplecov'
SimpleCov.start

require 'rubygems'
require 'sinatra'
require 'test/unit'
require 'rack/test'
require 'base64'
require 'json'
require 'timecop'
require './app1'

class ApplicationTest < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def make_a_passenger(passenger)
    put '/passengers', passenger.to_json
    assert_equal 201, last_response.status

    passenger = JSON.parse(last_response.body)
    refute_nil passenger['phonenum']
    assert_equal String, passenger['phonenum'].class
    assert_equal "/passengers/#{passenger['phonenum']}", last_response.headers['Location']

    passenger['phonenum'].to_s
  end

  def retrieve_passenger(phonenum)
    get '/passengers/' + phonenum
    assert_equal 200, last_response.status

    returned_passenger = JSON.parse(last_response.body)
    refute_nil returned_passenger
    
    returned_passenger
  end

  def test_add_passenger_empty
    put '/passengers', {}.to_json
    assert_equal 400, last_response.status
  end

  def test_add_passenger_no_phonenum
    put '/passengers', {"phonenum" => ""}.to_json
    assert_equal 500, last_response.status
  end

  def test_add_and_retrieve_passenger
    # Create a new passenger

    passenger = {
      "phonenum" => "0909123123"
    }

    phonenum = make_a_passenger(passenger)

    # Retrieve the passenger
    returned_passenger = retrieve_passenger(phonenum)

    # Check we got the same note back!
    passenger.each_key do |k|
      refute_nil returned_passenger[k]
      assert_equal passenger[k], returned_passenger[k]
    end
  end

  def test_add_booking_empty
    put '/passengers/booking', {}.to_json
    assert_equal 400, last_response.status
  end

  def test_add_booking_wrong_password
    put '/passengers/booking', {"phonenum" => "0909123123", "password" => "123", "lat" => "10.0", "long" => "10.0"}.to_json
    assert_equal 403, last_response.status
  end
end