require 'rubygems'
require 'sinatra'
require 'json'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-migrations'
require 'logger'
require 'sidekiq'
require 'sidekiq/web'

if development? # This is set by default, override with `RACK_ENV=production rackup`
  require 'sinatra/reloader'
  require 'debugger'
  Debugger.settings[:autoeval] = true
  Debugger.settings[:autolist] = 1
  Debugger.settings[:reload_source_on_change] = true
end
log = Logger.new(STDOUT)

configure :development, :production do
  set :datamapper_url, "sqlite3://#{File.expand_path('app2.sqlite3')}"
end
configure :test do
  set :datamapper_url, "sqlite3://#{File.expand_path('app2-test.sqlite3')}"
end

DataMapper.setup(:default, settings.datamapper_url)

require './models/drivers'

DataMapper.finalize

Driver.auto_upgrade!

class MessageWorker
  include Sidekiq::Worker

  def perform(msg)
    logger.info "SMS: " + msg
  end
end

class App2 < Sinatra::Base
  def jsonp(json)
    params[:callback] ? "#{params[:callback]}(#{json})" : json
  end

  before do
    content_type 'application/json'
  end

  get '/drivers' do
    drivers = Driver.all()
    halt 404 if drivers.nil?
    jsonp(drivers.to_a.to_json)
  end

  get '/drivers/:id' do
    driver = Driver.get(params[:id])
    halt 404 if driver.nil?
    jsonp(driver.to_json)
  end

  put '/drivers' do
    # Request.body.read is destructive, make sure you don't use a puts here.
    data = JSON.parse(request.body.read)

    # Normally we would let the model validations handle this but we don't
    # have validations yet so we have to check now and after we save.
    if data.nil? || data['phonenum'].nil? || data['name'].nil?
      halt 400
    end

    driver = Driver.create(
                :name => data['name'],
                :phonenum => data['phonenum'],
                :lat => data['lat'],
                :long => data['long'],
                :created_at => Time.now.utc,
                :updated_at => Time.now.utc)

    halt 500 unless driver.save

    # PUT requests must return a Location header for the new resource
    [201, {'Location' => "/drivers/#{driver.id}"}, jsonp(driver.to_json)]
  end

  # 10.7954196,106.6506274
  put '/drivers/nearest' do
    # Request.body.read is destructive, make sure you don't use a puts here.
    data = JSON.parse(request.body.read)

    # Normally we would let the model validations handle this but we don't
    # have validations yet so we have to check now and after we save.
    if data.nil? || data['lat'].nil? || data['long'].nil?
      halt 400
    end

    driver = Driver.findClosest(data['lat'], data['long'])

    halt 404 if driver.nil?
    MessageWorker.perform_async "Driver num: #{driver.phonenum} just got a message"

    jsonp(driver.to_json)
  end
end
