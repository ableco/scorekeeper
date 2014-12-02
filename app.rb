ENV['RACK_ENV'] ||= 'development'
require "bundler/setup"
Bundler.require :default, ENV['RACK_ENV'].to_sym
require "sinatra/json"
require "json"

get "/" do
  json "go away"
end

patch "/update" do
  body = JSON.parse(request.body.read)
  puts body["user"]
  puts body["score"]
  json "ok"
end