require 'rubygems'
require 'sinatra'
require 'json'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-migrations'
require 'keepass/password'
require 'net/http'
require 'logger'

if development? # This is set by default, override with `RACK_ENV=production rackup`
  require 'sinatra/reloader'
  require 'debugger'
  Debugger.settings[:autoeval] = true
  Debugger.settings[:autolist] = 1
  Debugger.settings[:reload_source_on_change] = true
end
log = Logger.new(STDOUT)

configure :development, :production do
  set :datamapper_url, "sqlite3://#{File.expand_path('app1.sqlite3')}"
end
configure :test do
  set :datamapper_url, "sqlite3://#{File.expand_path('app1-test.sqlite3')}"
end
DataMapper.setup(:default, settings.datamapper_url)

require './models/passenger'

DataMapper.finalize
Passenger.auto_upgrade!
Booking.auto_upgrade!

before do
  content_type 'application/json'
end

def jsonp(json)
  params[:callback] ? "#{params[:callback]}(#{json})" : json
end

get '/passengers/:phonenum' do
  passenger = Passenger.get(params[:phonenum])
  halt 404 if passenger.nil?
  jsonp(passenger.to_json)
end

put '/passengers' do
  # Request.body.read is destructive, make sure you don't use a puts here.
  data = JSON.parse(request.body.read)

  # Normally we would let the model validations handle this but we don't
  # have validations yet so we have to check now and after we save.
  if data.nil? || data['phonenum'].nil?
    halt 400
  end

  passenger = Passenger.get(data['phonenum'])
  unless passenger.nil?
    log.debug(passenger)
    [201, {'Location' => "/passengers/#{passenger.phonenum}"}, jsonp(passenger.to_json)]
  else
    passenger = Passenger.create(
                :phonenum => data['phonenum'],
                :password => KeePass::Password.generate('A{6}s'),
                :created_at => Time.now.utc,
                :updated_at => Time.now.utc)

    halt 500 unless passenger.save

    # PUT requests must return a Location header for the new resource
    [201, {'Location' => "/passengers/#{passenger.phonenum}"}, jsonp(passenger.to_json)]
  end
end

put '/passengers/booking' do
  data = JSON.parse(request.body.read)
  if data.nil? || data['phonenum'].nil? || data['password'].nil? || data['lat'].nil? || data['long'].nil? 
    halt 400
  end

  passenger = Passenger.get(data['phonenum'])
  log.debug(passenger)
  halt 403 if passenger.nil?
  halt 403 if passenger.password != data['password']

  uri = URI('http://localhost:8002/drivers/nearest')
  req = Net::HTTP::Put.new(uri.path, initheader = {'Content-Type' =>'application/json'})
  req.body = {lat: data['lat'], long: data['long']}.to_json

  res = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(req)
  end

  case res
  when Net::HTTPSuccess, Net::HTTPRedirection
    result = JSON.parse(res.body)
    log.debug(result)
    booking = Booking.create(
              :passenger => passenger,
              :drivername => result['name'],
              :drivernum => result['phonenum'],
              :created_at => Time.now.utc,
              :updated_at => Time.now.utc)

    halt 500 unless booking.save

    # # PUT requests must return a Location header for the new resource
    [201, {'Location' => "/passengers/booking/#{booking.id}"}, jsonp(booking.to_json)]
  else
    halt 404
  end

end