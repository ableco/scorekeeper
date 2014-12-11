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
  haml :scoreboard
end

post "/update" do
  body = JSON.parse(request.body.read)
  score = body["score"].to_i
  score_recipient = body["user"]
  scorer = body["scorer"]

  # lose a point if you try to give yourself points
  if score_recipient == scorer && score > 0
    score_recipient = scorer
    score = -1
  end

  # if you try to give someone less than -5 points, there's a 90% chance it gets assigned to you instead
  if score < -5 && rand(10) != 1
    score_recipient = scorer
  end

  unless score_recipient == nil or score_recipient == ""
    $redis.incrby(score_recipient, score)
    $redis.sadd("scores", score_recipient)
  end
  
  json "ok"
end