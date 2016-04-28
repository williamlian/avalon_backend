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
        self.id = 100000 + rand(900000)
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

    def is_all_ready?
        players.map {|k,p| p.is_ready ? 1 : 0}.sum == self.size
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

    def player_view(player)
        {
            id: id,
            player_count: player_count,
            size: size,
            state: state,
            players: players.map {|id,p| p.character_view(player.character)}
        }
    end

    def save!
        @file.rewind
        @file.truncate(0)
        @file.write(self.to_json.to_s)
        @file.flush
    end

    ########################### Static Members #######################
    # returns group uuid 
    def self.create(size)
        group = Group.new
        Group.with_update_lock(group.id) do |file|
            group.size = size
            group.set_file(file)
            group.save!
            group.set_file(nil)
        end
        group
    end

    # nil means file not found
    def self.load_for_update(id)
        begin
            with_update_lock(id) do |file|
                data = file.read
                group = Group.from_json(JSON.parse(data))
                group.set_file(file)
                yield group
                group.set_file(nil)
            end
        rescue Errno::ENOENT => e
            raise 'group not found: ' + e.to_s
        rescue Exception => e
            raise e
        end
    end

    def self.load_for_read(id)
        begin
            with_read_lock(id) do |file|
                data = file.read
                yield Group.from_json(JSON.parse(data))
            end
        rescue Errno::ENOENT => e
            raise 'group not found: ' + e.to_s
        rescue Exception => e
            raise e
        end
    end

    def self.with_read_lock(id)
        File.open(Group::GROUP_FILE_PATH + id.to_s, "r") do |f|
            f.flock(File::LOCK_SH)
            begin
                yield f
            rescue => e
                f.flock(File::LOCK_UN)
                raise e
            end
        end
    end

    def self.with_update_lock(id)
        # make sure the dir is there
        FileUtils.mkdir_p(Group::GROUP_FILE_PATH)
        # Obtain exclusive lock to prevent write correction
        File.open(Group::GROUP_FILE_PATH + id.to_s, File::RDWR|File::CREAT, 0644) do |f|
            f.flock(File::LOCK_EX)
            begin
                yield f
            rescue => e
                f.flock(File::LOCK_UN)
                raise e
            end
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

    ############################## Privates ###########################
    def set_file(file)
        @file = file
    end
end
