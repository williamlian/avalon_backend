require 'uuidtools'

class Player
	attr_accessor :id,
		:name,
		:photo,
		:is_admin,
		:character,
		:is_ready

	def initialize
		@id = UUIDTools::UUID.random_create.to_s
		@name = ''
		@photo = ''
		@is_admin = false
		@character = ''
		@is_ready = false
	end

	########################### Static Members #######################

	def self.from_json(json)
		player = Player.new
		player.id = json["id"]
		player.name = json["name"]
		player.photo = json["photo"]
		player.is_admin = json["is_admin"]
		player.character = json["character"]
		player.is_ready = json["is_ready"]
		return player
	end

end
