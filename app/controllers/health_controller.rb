require 'json'
require 'redis'

class HealthController < ApplicationController

	def initialize
		@redis = Redis.new({host: Rails.application.config.redis_host})
	end

	def status
		group_keys = @redis.keys('group.*')
		@groups = group_keys.map {|k| Group.from_json JSON.parse(@redis.get(k))}
	end

end