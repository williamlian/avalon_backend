require 'uuidtools'

class Player
	attr_accessor :id,
		:group_id,
		:name,
		:photo,
		:is_admin,
		:character,
		:is_ready

	PLAYER_STATE_CREATED = 'created'
	PLAYER_STATE_SETUP = 'setup'
	PLAYER_STATE_READY = 'ready'

	def initialize
		self.id = UUIDTools::UUID.random_create.to_s
		self.group_id = nil
		self.name = ''
		self.photo = ''
		self.is_admin = false
		self.character = ''
		self.is_ready = false
	end

	def render_self
		self.render.merge({id: id, is_admin: is_admin})
	end

	def render
		{
			group_id: group_id,
			name: name,
			photo: photo,
			character: character,
			is_ready: is_ready
		}
	end

	def character_view(viewing_character)
		{
			name: name,
			photo: photo,
			character: Character::VIEW_MAP[viewing_character][character],
			is_ready: is_ready
		}
	end

	########################### Static Members #######################

	def self.from_json(json)
		player = Player.new
		player.id = json["id"]
		player.group_id = json["group_id"]
		player.name = json["name"]
		player.photo = json["photo"]
		player.is_admin = json["is_admin"]
		player.character = json["character"]
		player.is_ready = json["is_ready"]
		player
	end

end
