require 'redis'
require 'json'

class PushController < ApplicationController
    include ActionController::Live
    
    def subscribe
        player_id = params[:player_id]
        redis = Redis.connect(timeout: 1800)
        
        response.headers['Content-Type'] = 'text/event-stream'
        
        begin
            puts "Subscribing #{player_id}"
            redis.subscribe("pub.#{player_id}") do |on|
              on.message do |channel, msg|
                if msg.to_i == 0
                    raise Interrupt.new('client unsubscribed')
                end
                response.stream.write "data: ${msg}\n\n"
              end
            end
        rescue Interrupt => e
            puts "Unsubscribed: #{player_id}"
        rescue IOError => e
            puts "Subscription for #{player_id} closed."
        rescue => e
            puts "Error: #{e}"
            puts e.backtrace.join("\n")
        ensure
            response.stream.close
        end
    end

    def unsubscribe
        player_id = params[:player_id]
        redis = Redis.connect

        redis.publish("pub.#{player_id}", 0)
        render :json => {}
    end
end