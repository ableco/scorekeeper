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
  
  unless scorers_points <= 0
    absolute_value_of_score = score.abs
    # change the score to the max their score allows if the scorers points are less than the absolute value of the score
    if scorers_points < absolute_value_of_score
      score = scorers_points * (score > 0 ? 1 : -1)
    end

    # decrenment scorer's score
    $redis.incrby(scorer, (score.abs * -1))

    $redis.incrby(score_recipient, score)    
  end


  # # lose a point if you try to give yourself points
  # if score_recipient == scorer && score > 0
  #   score_recipient = scorer
  #   score = -1
  # end

  # # if you try to give someone less than -5 points, there's a 90% chance it gets assigned to you instead
  # if score < -5 && rand(10) != 1
  #   score_recipient = scorer
  # end

  # # no +0 hack
  # if score == 0
  #   score = -1
  # end

  # unless score_recipient == nil or score_recipient == ""
  #   $redis.incrby(score_recipient, score)
  #   $redis.sadd("scores", score_recipient)
  # end
  
  json "ok"
end