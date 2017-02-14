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
        :winner

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
                self.vote_count = 0
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
            fail_required = self.setting[:fails][self.quest_number]

            self.quests.push({
                success: success.length,
                failed: failed.length,
                result: failed.length < fail_required
            })
            puts "check quest: #{success.length} / #{failed.length}"
            self.players.values.each do |p| 
                p.last_quest_result = nil
                p.status = Player::PLAYER_STATE_READY
            end

            success_count = self.quests.select{|q| q[:result]}.length
            failed_count = self.quests.select{|q| !q[:result]}.length
            if success_count > GameSetting::MAX_QUEST / 2
                self.clean_vote
                self.status = GROUP_STATE_ASSASSINATION
            elsif failed_count > GameSetting::MAX_QUEST / 2
                self.clean_vote
                self.status = GROUP_STATE_END
                self.winner = Character::SIDE_EVIL
            elsif self.quest_number > GameSetting::MAX_QUEST
                self.clean_vote
                self.status = GROUP_STATE_END
                self.winner = nil
            else
                self.end_turn
            end
        end
    end

    def setting
        return GameSetting::GAME[self.size]
    end

    def quest_number
        return self.quests.length + 1
    end

    def last_quest_result
        if self.quests.length == 0
            return {success: 0, failed: 0, result: nil}
        else
            return self.quests[-1]
        end
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

    # def render
    #     {
    #         id: id,
    #         player_count: player_count,
    #         size: size,
    #         status: status,
    #         players: players.map {|id,p| p.render},
    #         last_vote_result: last_vote_result,
    #         quest_result: last_quest_result,
    #         vote_count: vote_count,
    #         quests: quests,
    #         winner: winner
    #     }
    # end

    def player_view(player)
        player_view_list = []
        if player.is_ready
            if self.status == GROUP_STATE_ASSASSINATION
                player_view_list = players.map {|id,p| p.assassination_view(player.character)}
            else
                player_view_list = players.map {|id,p| p.character_view(player.character)}
            end
        end
        
        {
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
            winner: winner

        }
    end

    def save!(redis)
        if redis.nil?
            raise 'cannot save, redis not ready'
        end
        redis.set(self.redis_key, self.to_json.to_s)

        # publish to every player
        self.players.each do |id, player|
            redis.publish("pub.#{player.id}", 'update')
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
        group.quests = json["quests"]
        group.vote_count = json["vote_count"].to_i
        group.winner = json["winner"]
        group
    end
end
