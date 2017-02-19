require 'redis'
require 'json'

class PushController < ApplicationController
    include ActionController::Live

    def initialize
        @redis = Redis.new({host: Rails.application.config.redis_host, timeout: 3600})
    end
    
    def subscribe
        player_id = params[:player_id]
        
        response.headers['Content-Type'] = 'text/event-stream'
        
        begin
            puts "Subscribing #{player_id}"
            @redis.subscribe("pub.#{player_id}") do |on|
              on.message do |channel, msg|
                json = JSON.parse(msg)
                if json["type"] == 'cancel'
                    raise Interrupt.new('client unsubscribed')
                end
                response.stream.write "data: #{msg}\n\n"
                if json["type"] == 'abandon'
                    raise Interrupt.new('client abandoned')
                end
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

        @redis.publish("pub.#{player_id}", {type: 'cancle'}.to_json)
        render :json => {}
    end
end