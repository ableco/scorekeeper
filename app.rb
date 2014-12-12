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
  hash = Hash[*(members.collect { |x| [ x, $redis.get(x).to_i ]}).flatten]
  @rankings = hash.sort_by { |name, score| score }.reverse
  # @rankings = [
  #   ["Ben", 30],
  #   ["Ben", 23],
  #   ["Ben", 13],
  #   ["Ben", 1],
  #   ["Ben", -1],
  #   ["Ben", -3],
  #   ["Ben", -22],
  #   ["Ben", -32323],
  #   ["Ben", -55553],
  #   ["Ben", -99993]
  # ]
  haml :scoreboard
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