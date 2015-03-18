ENV['RACK_ENV'] ||= 'development'
require "bundler/setup"
Bundler.require :default, ENV['RACK_ENV'].to_sym
require "sinatra/json"
require 'sinatra/cross_origin'

require "json"

configure do
  enable :cross_origin
  if ENV["REDISCLOUD_URL"]
    uri = URI.parse(ENV["REDISCLOUD_URL"])
    $redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
  else
    $redis = Redis.new(:host => "localhost", :port => 6379)
  end
end

# get "/" do
#   members = $redis.smembers("scores")
#   hash = Hash[*(members.collect { |x| [ x, $redis.get(x).to_i ]}).flatten]
#   @rankings = hash.sort_by { |name, score| score }.reverse
#   haml :scoreboard
# end

get "/scores" do
  members = $redis.smembers("scores")
  json members.collect { |x| { :name => x, :score => $redis.get(x).to_i } }.sort{ |x, y| x["score"] <=> y["score"] }.reverse
end

# get a point for every comment
post "/comment" do
  body = JSON.parse(request.body.read)
  commenter = body["user"]
  room = body["room"]

  if room == "water-cooler"
    $redis.incrby(commenter, 1)
    $redis.sadd("scores", commenter)
  end
  
  json "ok"
end

post "/trivia_answer" do
  body = JSON.parse(request.body.read)
  answerer = body["user"]
  points = body["points"].to_i
  $redis.incrby(answerer, points)
  $redis.sadd("scores", answerer)

  json "ok"
end

post "/plus_and_minus" do
  body = JSON.parse(request.body.read)
  score = body["score"].to_i
  score_recipient = body["user"]
  scorer = body["scorer"]

  scorers_points = $redis.get(scorer).to_i
  
  if scorers_points <= 0
    json "no points to use"
  else
    # change the score to the max their score allows if the scorers points are less than the absolute value of the score
    if scorers_points < score.abs
      score = scorers_points * (score > 0 ? 1 : -1)
    end

    # decrement scorer's score
    $redis.decrby(scorer, score.abs)

    # increment recipient's score
    $redis.incrby(score_recipient, score)    
  end
  
  json "ok"
end