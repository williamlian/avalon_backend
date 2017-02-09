require 'redis'
require 'json'

class PushController < ApplicationController
    include ActionController::Live
    
    def subscribe
        group_id = params[:group_id]
        redis = Redis.connect(timeout: 36000)
        
        response.headers['Content-Type'] = 'text/event-stream'
        
        begin
            puts "Subscribing #{group_id}"
            redis.subscribe("pub.#{group_id}") do |on|
              on.message do |channel, msg|
                response.stream.write "msg"
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