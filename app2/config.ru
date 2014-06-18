require './app2.rb'
require 'sidekiq/web'

run App2
run Rack::URLMap.new('/' => App2, '/sidekiq' => Sidekiq::Web)
