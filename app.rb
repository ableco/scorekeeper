ENV['RACK_ENV'] ||= 'development'
require "bundler/setup"
Bundler.require :default, ENV['RACK_ENV'].to_sym
require "sinatra/json"
require "json"

configure do
  if ENV["REDISCLOUD_URL"]
    uri = URI.parse(ENV["REDISCLOUD_URL"])
    $redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
  else
    $redis = Redis.new(:host => "localhost", :port => 6379)
  end
end

get "/" do
  members = $redis.smembers("scores")
  hash = Hash[*(members.collect { |x| [ x, $redis.get(x) ]}).flatten]
  json hash
end

post "/update" do
  body = JSON.parse(request.body.read)
  $redis.incrby(body["user"], body["score"].to_i)
  $redis.sadd("scores", body["user"])
  json $redis.get(body["user"])
end