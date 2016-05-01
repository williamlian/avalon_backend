require 'uuidtools'

class Player
	extend FileLock
	attr_accessor :id,
		:group_id,
		:name,
		:photo,
		:is_admin,
		:character,
		:is_ready,
		:is_king,
		:status

	PLAYER_FILE = '/var/tmp/avalon/players'

	PLAYER_STATE_CREATED = 'created'
	PLAYER_STATE_READY = 'ready'

	def initialize
		self.id = UUIDTools::UUID.random_create.to_s
		self.group_id = nil
		self.name = ''
		self.photo = ''
		self.is_admin = false
		self.character = ''
		self.is_ready = false
		self.is_king = false
		self.status = PLAYER_STATE_CREATED
	end

	def render_self
		self.render.merge({id: id, is_admin: is_admin})
	end

	def ready(name, photo)
		self.name = name
		self.photo =photo
		self.status = PLAYER_STATE_READY
		self.is_ready = true
	end

	def render
		{
			group_id: group_id,
			name: name,
			photo: photo,
			character: character,
			is_ready: is_ready,
			is_king: is_king,
			status: status
		}
	end

	def character_view(viewing_character)
		mapped_character = Character::VIEW_MAP[viewing_character][character] rescue nil
		{
			name: name,
			photo: photo,
			character: mapped_character,
			is_ready: is_ready,
			is_king: is_king,
		}
	end

	########################### Static Members #######################

	# methods for player map
    def self.add_player(player)
        with_update_lock(PLAYER_FILE) do |file|
        	puts "saving player " + player.id
        	data = file.read
        	data = '{}' if data.empty?
            player_map = JSON.parse(data)
            player_map[player.id] = player.group_id
            file.rewind
	        file.truncate(0)
	        file.write(player_map.to_json.to_s)
	        file.flush
        end
    end

    def self.remove_player(player_id)
    	with_update_lock(PLAYER_FILE) do |file|
            player_map = JSON.parse(file.read)
            player_map.delete(player_id)
            file.rewind
	        file.truncate(0)
	        file.write(player_map.to_json.to_s)
	        file.flush
	    end
	end

    def self.find_group_id_by_player_id(player_id)
    	group_id = nil
        begin
            with_read_lock(PLAYER_FILE) do |file|
                player_map = JSON.parse(file.read)
                group_id = player_map[player_id]
            end
        rescue Errno::ENOENT => e
            group_id = nil
        rescue Exception => e
            raise e
        end
        group_id
    end

	def self.from_json(json)
		player = Player.new
		player.id = json["id"]
		player.group_id = json["group_id"]
		player.name = json["name"]
		player.photo = json["photo"]
		player.is_admin = json["is_admin"]
		player.character = json["character"]
		player.is_ready = json["is_ready"]
		player.is_king = json["is_king"]
		player.status = json["status"]
		player
	end
end
