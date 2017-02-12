require 'redis'
require 'json'

class PushController < ApplicationController
    include ActionController::Live
    
    def subscribe
        player_id = params[:player_id]
        redis = Redis.connect(timeout: 5000)
        group_id = redis.get(player_id)
        
        response.headers['Content-Type'] = 'text/event-stream'
        
        begin
            puts "Subscribing #{group_id}"
            redis.subscribe("pub.#{group_id}") do |on|
              on.message do |channel, msg|
                response.stream.write "data: ${msg}\n\n"
              end
            end
        rescue => e
            puts "Subscription for #{group_id} closed."
            puts "Error: #{e}"
            puts e.backtrace.join("\n")
        ensure
            response.stream.close
        end
    end
end