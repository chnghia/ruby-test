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
require './app2'

class ApplicationTest < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def app
    App2
  end

  def make_a_driver(driver)
    put '/drivers', driver.to_json
    assert_equal 201, last_response.status

    driver = JSON.parse(last_response.body)
    refute_nil driver['id']
    assert_equal Fixnum, driver['id'].class
    assert_equal "/drivers/#{driver['id']}", last_response.headers['Location']

    driver['id'].to_s
  end

  def retrieve_driver(id)
    get '/drivers/' + id.to_s
    assert_equal 200, last_response.status

    returned_driver = JSON.parse(last_response.body)
    refute_nil returned_driver
    
    returned_driver
  end

  def test_add_and_retrieve_driver
    # Create a new driver

    driver = {
    	"name" => "Test Driver",
      "phonenum" => "0909123123",
      "lat" => 10.10,
      "long" => 10.20
    }

    id = make_a_driver(driver)

    # Retrieve the driver
    returned_driver = retrieve_driver(id)

    # Check we got the same note back!
    driver.each_key do |k|
      refute_nil returned_driver[k]
      assert_equal driver[k], returned_driver[k]
    end
  end
end