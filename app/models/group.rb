require 'uuidtools'

class Group
    extend FileLock
    attr_accessor :id, 
        :player_count, 
        :size, 
        :status, 
        :players, 
        :character_pool,
        :owner,
        :last_vote_result,
        :quest_result

    GROUP_FILE_PATH = '/var/tmp/avalon/groups/'

    GROUP_STATE_CREATED = 'created'
    GROUP_STATE_OPEN    = 'open'
    GROUP_STATE_STARTED = 'started'
    GROUP_STATE_VOTING  = 'voting'
    GROUP_STATE_QUEST   = 'quest'

    def initialize
        self.id = 100000 + rand(900000)
        self.player_count = 0
        self.size = 0
        self.status = GROUP_STATE_CREATED
        self.players = {}
        self.character_pool = []
        self.owner = nil
        self.last_vote_result = nil
        self.quest_result = {success: 0, failed: 0}
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
        if self.status != GROUP_STATE_OPEN
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
        sequence_ids = self.players.values.map{|p| p.player_sequence}
        (0...self.size).each do |i|
            if !i.in?(sequence_ids)
                player.player_sequence = i
                break
            end
        end
        self.player_count += 1
        player.group_id = self.id
        Player.add_player(player)
        player
    end

    def remove_player(player)
        removed = self.players.delete(player.id)
        self.player_count = self.players.keys.length
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

    def choose_king
        iKing = rand(self.player_count)
        king = self.players.values[iKing]
        king.is_king = true
    end

    def next_king
        king = self.players.values.select{|p| p.is_king}[0]
        if king.nil?
            raise 'no king found'
        end
        king.is_king = false
        iKing = self.players.values.index(king)
        iKing = (iKing + 1) % self.size
        self.players.values[iKing].is_king = true
    end

    # update the candidate pool
    # - only owner can call
    # - can only be called in created state
    # - change group state to open (open for join)
    def update_character_pool(player_id, new_candidates)
        if !is_owner?(player_id)
            raise 'not owner'
        elsif self.status != Group::GROUP_STATE_CREATED
            raise 'group is open for joining already'
        elsif new_candidates.length != self.size
            raise 'candidate size does not match group size'
        end
        self.character_pool = new_candidates
        self.status = Group::GROUP_STATE_OPEN
    end

    def is_owner?(player_id)
        return self.owner == player_id
    end

    def has_player?(player_id)
        return !self.players[player_id].nil?
    end

    def is_all_ready?
        ready = self.players.values.select{|p| p.is_ready}.length
        puts "ready players: #{ready} / #{self.size}"
        return ready == self.size
    end

    def render
        {
            id: id,
            player_count: player_count,
            size: size,
            status: status,
            players: players.map {|id,p| p.render},
            last_vote_result: last_vote_result,
            quest_result: quest_result,
        }
    end

    def player_view(player)
        {
            id: id,
            player_count: player_count,
            size: size,
            status: status,
            players: players.map {|id,p| p.character_view(player.character)},
            last_vote_result: last_vote_result,
            quest_result: quest_result,
        }
    end

    def start_vote(player_sequences)
        knights = self.players.values.select{|p| p.player_sequence.in?(player_sequences)}
        puts "knights selected: " + knights.map{|k|k.name}.join(",")
        knights.each {|k| k.is_knight = true}
        self.status = Group::GROUP_STATE_VOTING
    end

    def check_vote
        voted = self.players.values.reject{|p| p.last_vote.nil?}
        if voted.length < self.player_count
            puts "waiting for vote #{voted.length}/#{self.player_count}"
            self.last_vote_result = nil
        else
            accepted = voted.select{|v|v.last_vote}
            rejected = voted.reject{|v|v.last_vote}
            if accepted.length > rejected.length
                puts "vote passed #{accepted.length}/#{rejected.length}"
                self.last_vote_result = true
            else
                puts "vote rejected #{accepted.length}/#{rejected.length}"
                self.last_vote_result = false
            end
        end
    end

    def start_quest
        # clear voting state
        self.players.values.each{|p|p.last_vote = nil}
        self.last_vote_result = nil
        # set group state to quest
        self.quest_result[:success] = 0
        self.quest_result[:failed] = 0
        self.players.values.each do |player|
            if player.is_knight
                player.status = Player::PLAYER_STATE_QUEST
            end
        end
        self.status = GROUP_STATE_QUEST
    end

    def end_turn
        # clear voting state
        self.players.values.each{|p|p.last_vote = nil}
        self.last_vote_result = nil
        # clear knight candidates
        self.players.values.each{|p|p.is_knight = false}
        # move king
        self.next_king
        # move back to play mode
        self.status = GROUP_STATE_STARTED
    end

    def check_quest
        knights = self.players.values.select{|p| p.is_knight}
        voted_knights = knights.reject{|k| k.last_quest_result.nil?}
        if voted_knights.length < knights.length
            puts "waiting for quest result #{voted_knights.length}/#{knights.length}"
        else
            success = voted_knights.select{|v|v.last_quest_result}
            failed = voted_knights.reject{|v|v.last_quest_result}
            self.quest_result[:success] = success.length
            self.quest_result[:failed] = failed.length
            puts "check quest: #{success.length} / #{failed.length}"
            self.players.values.each do |p| 
                p.last_quest_result = nil
                p.status = Player::PLAYER_STATE_READY
            end
            self.end_turn
        end
    end

    def save!
        if @file.nil?
            raise 'cannot save, please obtain an exclusive lock first'
        end
        @file.rewind
        @file.truncate(0)
        @file.write(self.to_json.to_s)
        @file.flush
    end

    ########################### Static Members #######################
    # returns group uuid 
    def self.create(size)
        group = Group.new
        with_update_lock(file_from_id(group.id)) do |file|
            group.size = size
            group.set_file(file)
            yield group
            group.set_file(nil)
        end
        group
    end

    def self.remove(group_id)
        file = file_from_id(group_id)
        File.unlink(file)
    end

    # nil means file not found
    def self.load_for_update(id)
        with_update_lock(file_from_id(id)) do |file|
            data = file.read
            if data.empty?
                raise 'group not found'
            end
            group = Group.from_json(JSON.parse(data))
            group.set_file(file)
            yield group
            group.set_file(nil)
        end
    end

    def self.load_for_read(id)
        begin
            with_read_lock(file_from_id(id)) do |file|
                data = file.read
                yield Group.from_json(JSON.parse(data))
            end
        rescue Errno::ENOENT => e
            raise 'group not found: ' + e.to_s
        rescue Exception => e
            raise e
        end
    end

    def self.from_json(json)
        group = Group.new
        group.id = json["id"]
        group.player_count = json["player_count"]
        group.size = json["size"]
        group.status = json["status"]
        group.players = {}
        if json["players"] != nil
            json["players"].keys.each do |pid|
                group.players[pid] = Player.from_json(json["players"][pid])
            end
        end
        group.character_pool = json["character_pool"]
        group.owner = json["owner"]
        group.last_vote_result = json["last_vote_result"]
        group.quest_result = json["quest_result"]
        group
    end

    def self.file_from_id(id)
        GROUP_FILE_PATH + '/' + id.to_s
    end

    ############################## Privates ###########################
    def set_file(file)
        @file = file
    end
end
