require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-migrations'
require 'dm-sweatshop' # for fixtures

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

def rand_float(min, max); rand * (max - min) + min end

Driver.fix {{
  :name => /[:name:]/.gen,
  :phonenum => /\d{10}/.gen,
  :lat => rand_float(10.5, 10.9),
  :long => rand_float(106.1, 106.5),
  :created_at => Time.now.utc,
  :updated_at => Time.now.utc
}}

100.of { Driver.gen }
