require 'uuidtools'

class Group
    attr_accessor :id, 
        :player_count, 
        :size, 
        :state, 
        :players, 
        :character_pool,
        :owner

    GROUP_FILE_PATH = '/var/tmp/avalon/groups/'

    GROUP_STATE_CREATED = 'created'
    GROUP_STATE_OPEN    = 'open'
    GROUP_STATE_STARTED = 'started'

    def initialize
        self.id = UUIDTools::UUID.random_create.to_s
        self.player_count = 0
        self.size = 0
        self.state = GROUP_STATE_CREATED
        self.players = {}
        self.character_pool = []
        self.owner = nil
    end

    # returns a  Player
    def join_as_owner()
        player = Player.new
        self.owner = player.id
        player.is_admin = true
        self.add_player(player)
    end

    # returns a Player
    def join_as_player()
        if self.state != GROUP_STATE_OPEN
            raise 'not ready for joining'
        end
        player = Player.new
        self.add_player(player)
    end

    # returns boolean, add successful or not
    def add_player(player)
        if self.player_count >= self.size
            raise 'no more space'
        end
        if !self.players[player.id].nil?
            raise 'user id ' + player.id + ' exists'
        end
        self.players[player.id] = player
        self.player_count += 1
        player.group_id = self.id
        player
    end

    # given a player assign a character for the player and update group
    # candidate list.
    # - return true when success
    #   return false when the player is not found from the group
    def assign_character(player)
        if !self.has_player?(player.id)
            raise 'player not found'
        end
        character_pool_size = self.character_pool.length
        character_index = rand(character_pool_size)
        character = self.character_pool.delete_at(character_index)
        player.character = character
    end

    # update the candidate pool
    # - only owner can call
    # - can only be called in created state
    # - change group state to open (open for join)
    def update_character_pool(player_id, new_candidates)
        if !is_owner?(player_id)
            raise 'not owner'
        elsif self.state != Group::GROUP_STATE_CREATED
            raise 'group is open for joining already'
        elsif new_candidates.length != self.size
            raise 'candidate size does not match group size'
        end
        self.character_pool = new_candidates
        self.state = Group::GROUP_STATE_OPEN
    end

    def is_owner?(player_id)
        return self.owner == player_id
    end

    def has_player?(player_id)
        return !self.players[player_id].nil?
    end

    def render
        {
            id: id,
            player_count: player_count,
            size: size,
            state: state,
            players: players.map {|id,p| p.render}
        }
    end


    ########################### Static Members #######################
    # returns group uuid 
    def self.create(size)
        group = Group.new
        group.size = size
        group.character_pool = Character.candidate_pool
        group
    end

    # nil means file not found
    def self.load(uuid)
        file_path = GROUP_FILE_PATH + uuid
        begin
            File.open(file_path, "r") {|f|
                f.flock(File::LOCK_SH)
                data = f.read
                return Group.from_json(JSON.parse(data))
            }
        rescue Exception => e
            raise 'group not found: ' + e.to_s
        end
    end

    def self.from_json(json)
        group = Group.new
        group.id = json["id"]
        group.player_count = json["player_count"]
        group.size = json["size"]
        group.state = json["state"]
        group.players = {}
        if json["players"] != nil
            json["players"].keys.each do |pid|
                group.players[pid] = Player.from_json(json["players"][pid])
            end
        end
        group.character_pool = json["character_pool"]
        group.owner = json["owner"]
        group
    end

    ############################## Members ###########################
    def file_path
        Group::GROUP_FILE_PATH + @id
    end

    def save!
        # make sure the dir is there
        FileUtils.mkdir_p(Group::GROUP_FILE_PATH)
        # Obtain exclusive lock to prevent write correction
        File.open(self.file_path, File::RDWR|File::CREAT, 0644) {|f|
            f.flock(File::LOCK_EX)
            f.truncate(0)
            f.write(self.to_json.to_s)
            f.flush
        }
        puts "group saved to " + self.file_path
    end

end
