require 'uuidtools'
require 'json'

class Group
    attr_accessor :id, 
        :player_count, 
        :size, 
        :status, 
        :players, 
        :character_pool,
        :owner,
        :last_vote_result,

        :vote_count,
        :quests,
        :winner,
        :win_by,

        :test

    GROUP_STATE_CREATED         = 'created'         # means still need character setting, not ready to jion
    GROUP_STATE_OPEN            = 'open'            # means open for joining
    GROUP_STATE_STARTED         = 'started'         # means there is no more space, game starts
    GROUP_STATE_VOTING          = 'voting'          # means kinghts has been selected, waiting to vote
    GROUP_STATE_QUEST           = 'quest'           # means votes approved, starting quest
    GROUP_STATE_ASSASSINATION   = 'assassination'   # means the evil turn to identify merlin
    GROUP_STATE_END             = 'end'             # means game ended

    def initialize
        self.id = 100000 + rand(900000)
        self.player_count = 0
        self.size = 0
        self.status = GROUP_STATE_CREATED
        self.players = {}
        self.character_pool = []
        self.owner = nil
        self.last_vote_result = nil

        self.vote_count = 0
        self.quests = []
        self.winner = nil
        self.win_by = nil

        self.test = false
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
        player
    end

    def remove_player(player)
        character_pool.push player.character
        players.delete(player.id)
        self.player_count -= 1
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
        if self.test
            return
        end
        king = self.players.values.find{|p| p.is_king}
        if king.nil?
            raise 'no king found'
        end
        king.is_king = false
        iKing = king.player_sequence
        iKing = (iKing + 1) % self.size
        self.players.values.find{|p| p.player_sequence == iKing}.is_king = true
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

    def nominate(player_sequences)
        self.players.values.each do |player|
            if player.player_sequence.in?(player_sequences)
                player.is_knight = true
            else
                player.is_knight = false
            end
        end
    end

    def start_vote()
        knights = self.players.values.select{|p| p.is_knight}
        if knights.empty?
            raise 'no knights selected'
        end
        if knights.length != knights_required
            raise "must select #{knights_required} knights"
        end
        puts "knights selected: " + knights.map{|k|k.name}.join(",")
        self.vote_count += 1
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

                if self.vote_count == GameSetting::MAX_VOTE
                    self.status = GROUP_STATE_END
                    self.winner = Character::SIDE_EVIL
                end
            end
        end
    end

    def start_quest
        # clear voting state
        self.players.values.each{|p|p.last_vote = nil}
        self.last_vote_result = nil
        self.vote_count = 0
        # set group state to quest
        self.players.values.each do |player|
            if player.is_knight
                player.status = Player::PLAYER_STATE_QUEST
            end
        end
        self.status = GROUP_STATE_QUEST
    end

    # clean up remine states of voting
    def clean_vote
        # clear voting state
        self.players.values.each{|p|p.last_vote = nil}
        self.last_vote_result = nil
        # clear knight candidates
        self.players.values.each{|p|p.is_knight = false}
    end

    # end turn does not reset vote count, only a quest will
    def end_turn
        self.clean_vote
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

            self.quests.push({
                success: success.length,
                failed: failed.length,
                result: failed.length < self.fails_required
            })
            puts "check quest: #{success.length} / #{failed.length}, fails_required: #{self.fails_required}"
            self.players.values.each do |p| 
                p.last_quest_result = nil
                p.status = Player::PLAYER_STATE_READY
            end

            success_count = self.quests.select{|q| q[:result]}.length
            failed_count = self.quests.reject{|q| q[:result]}.length
            puts "quest status: #{success_count} / #{failed_count} over #{GameSetting::MAX_QUEST}"
            puts self.quests.to_json.to_s

            if success_count > GameSetting::MAX_QUEST / 2
                self.clean_vote
                self.status = GROUP_STATE_ASSASSINATION
            elsif failed_count > GameSetting::MAX_QUEST / 2
                self.clean_vote
                self.status = GROUP_STATE_END
                self.winner = Character::SIDE_EVIL
                self.win_by = 'quest'
            elsif self.quest_number > GameSetting::MAX_QUEST
                self.clean_vote
                self.status = GROUP_STATE_END
                self.winner = nil
            else
                self.end_turn
            end
        end
    end

    def nominate_assassination(target)
        if target.is_evil?
            raise 'cannot assassinate an evil player'
        end
        self.players.values.each {|p| p.assassination_target = false}
        target.assassination_target = true
    end

    def assassinate(player)
        if self.status != Group::GROUP_STATE_ASSASSINATION
            raise 'not in assassination section'
        end

        if player.character == Character::MERLIN
            self.status = GROUP_STATE_END
            self.winner = Character::SIDE_EVIL
            self.win_by = 'assassination'
        else
            self.status = GROUP_STATE_END
            self.winner = Character::SIDE_GOOD
            self.win_by = 'quest'
        end
    end

    def setting
        return GameSetting::GAME[self.size]
    end

    def quest_number
        return self.quests.length + 1
    end

    def knights_required
        return self.setting[:knights][self.quest_number - 1]
    end

    def fails_required
        return self.setting[:fails][self.quest_number - 1]
    end

    def last_quest_result
        if self.quests.length == 0
            return {success: 0, failed: 0, result: nil}
        else
            return self.quests[-1]
        end
    end

    def has_vote_result
        not self.last_vote_result.nil?
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

    def player_view(player)
        player_view_list = []
        type = :normal
        if has_vote_result
            type = :vote
        elsif status == GROUP_STATE_ASSASSINATION
            type = :assassination
        elsif status == GROUP_STATE_END
            type = :end
        end

        if player.is_ready
            player_view_list = players.map {|id,p| p.character_view(player.character, type)}
        end
        
        return {
            id: id,
            player_count: player_count,
            size: size,
            status: status,
            players: player_view_list,
            setting: GameSetting::GAME[size],

            last_vote_result: last_vote_result,
            quest_result: last_quest_result,
            vote_count: vote_count,
            quests: quests,
            winner: winner,
            win_by: win_by,
            knights_required: knights_required,
            fails_required: fails_required
        }
    end

    def save!(redis)
        if redis.nil?
            raise 'cannot save, redis not ready'
        end
        redis.set(self.redis_key, self.to_json.to_s)

        # publish to every player
        self.players.each do |id, player|
            player_data = {group: player_view(player), player: player.render_self}
            message = {type: 'update', data: player_data}.to_json
            redis.publish("pub.#{player.id}", message)
        end
    end
    
    def redis_key
        return "group.#{self.id}"
    end

    ########################### Static Members #######################
    def self.load(group_id, redis)
        json = redis.get("group.#{group_id}")
        if json.nil?
            raise 'Group not found'
        end
        return Group.from_json(JSON.parse(json))
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
        group.quests = json["quests"].map do |q|
            {
                success: q["success"],
                failed: q["failed"],
                result: q["result"]
            }
        end
        group.vote_count = json["vote_count"].to_i
        group.winner = json["winner"]
        group.win_by = json["win_by"]
        group.test = json["test"]
        group
    end
end
