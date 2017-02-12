require 'json'
require 'redis'
require 'redis-lock'

class GroupController < ApplicationController
    
    def initialize
        @redis = Redis.new
    end

    # create a new group, automatically add the current user as owner
    def create
        group_size = params[:size]
        
        run_with_rescue do
            group = Group.new
            # lock on group ID
            @redis.lock(group.id) do |lock|
                group.size = group_size.to_i
                player = group.join_as_owner()
                group.save!(@redis)
                @redis.set(player.id, group.id)
                render_success({group: group.render, player: player.render_self})
            end
        end
    end

    # setup group characters, and make the group join-able.
    def update_characters
        player_id = params[:player_id]
        group_id = params[:group_id]
        candidates = params[:characters]

        run_with_rescue do 
            if !Character.validate_list(candidates)
                raise 'not valid character pool'
            end
            @redis.lock(group_id) do |lock|
                group = Group.load(group_id, @redis)
                if group.nil?
                    raise 'group not found'
                end
                group.update_character_pool(player_id, candidates)
                group.save!(@redis)
                player = group.players[player_id]
                render_success({group: group.render, player: player.render_self})
            end
        end
    end

    # Player start to join the game
    def join
        group_id = params[:group_id]
        run_with_rescue do
            @redis.lock(group_id) do |lock|
                group = Group.load(group_id, @redis)
                player = group.join_as_player
                group.save!(@redis)
                @redis.set(player.id, group.id)
                render_success({group: group.render, player: player.render_self})
            end
        end
    end

    # mark a player as ready, which will implicitly assign a character.
    def ready
        player_id = params[:player_id]
        name = params[:name]
        photo = params[:photo]
        run_with_rescue do
            group_id = @redis.get(player_id)
            @redis.lock(group_id) do |lock|
                group = Group.load(group_id, @redis)
                if !group.has_player?(player_id)
                    raise 'player not found'
                end
                player = group.players[player_id]
                if player.is_ready
                    raise 'player is ready'
                end
                group.assign_character(player)
                player.ready(name, photo)
                if group.is_all_ready?
                    group.status = Group::GROUP_STATE_STARTED
                    group.choose_king
                end
                group.save!(@redis)
                render_success({group: group.render, player: player.render_self})
            end
        end
    end

    # The place the player gets latest game state
    def player_view
        player_id = params[:player_id]
        run_with_rescue do
            group_id = @redis.get(player_id)
            @redis.lock(group_id) do |lock|
                group = Group.load(group_id, @redis)
                if !group.has_player?(player_id)
                    raise 'player not found'
                end
                player = group.players[player_id]
                # if !player.is_ready
                #     raise 'player is not ready'
                # end
                if group.status == Group::GROUP_STATE_CREATED
                    raise 'group is not open yet'
                end
                render_success({group: group.player_view(player), player: player.render_self})
            end
        end
    end

    # knights is a list of user sequences
    def start_vote
        player_id = params[:player_id]
        knights = params[:knights].map{|x|x.to_i}
        run_with_rescue do
            group_id = @redis.get(player_id)
            @redis.lock(group_id) do |lock|
                group = Group.load(group_id, @redis)
                if group.status == Group::GROUP_STATE_VOTING
                    raise 'voting is already started'
                elsif group.status != Group::GROUP_STATE_STARTED
                    raise 'game is not started'
                end
                player = group.players[player_id]
                if !player.is_king
                    raise 'only king can start voting'
                end
                group.start_vote(knights)
                group.save!(@redis)
                render_success({})
            end
        end
    end

    def vote
        player_id = params[:player_id]
        vote = params[:vote]
        run_with_rescue do
            group_id = @redis.get(player_id)
            @redis.lock(group_id) do
                group = Group.load(group_id, @redis)
                if group.status != Group::GROUP_STATE_VOTING
                    raise 'voting is not acceptable currently'
                end
                player = group.players[player_id]
                unless player.last_vote.nil?
                    raise 'you voted already'
                end
                player.last_vote = vote
                group.check_vote
                group.save!(@redis)
                render_success({})
            end
        end
    end

    def start_quest
        player_id = params[:player_id]
        run_with_rescue do
            group_id = @redis.get(player_id)
            @redis.lock(group_id) do
                group = Group.load(group_id, @redis)
                if group.status != Group::GROUP_STATE_VOTING
                    raise 'not in voting section'
                end
                player = group.players[player_id]
                unless player.is_king
                    raise 'only king can start quest'
                end
                unless group.last_vote_result == true
                    raise 'vote is not accepted'
                end
                group.start_quest
                group.save!(@redis)
                render_success({})
            end
        end
    end

    def end_turn
        player_id = params[:player_id]
        run_with_rescue do
            group_id = @redis.get(player_id)
            @redis.lock(group_id) do
                group = Group.load(group_id, @redis)
                if group.status != Group::GROUP_STATE_VOTING
                    raise 'not in voting section'
                end
                player = group.players[player_id]
                unless player.is_king
                    raise 'only king can start quest'
                end
                unless group.last_vote_result == false
                    raise 'vote is not rejected, please start quest'
                end
                group.end_turn
                group.save!(@redis)
                render_success({})
            end
        end
    end

    def submit_quest
        player_id = params[:player_id]
        quest_result = params[:quest_result]
        run_with_rescue do
            group_id = @redis.get(player_id)
            @redis.lock(group_id) do
                group = Group.load(group_id, @redis)
                if group.status != Group::GROUP_STATE_QUEST
                    raise 'not in quest section'
                end
                player = group.players[player_id]
                unless player.is_knight
                    raise 'only knight can submit quest'
                end
                unless player.last_quest_result.nil?
                    raise 'you submitted already'
                end
                player.last_quest_result = quest_result
                player.status = Player::PLAYER_STATE_READY
                group.check_quest
                group.save!(@redis)
                render_success({})
            end
        end
    end

    # admin function
    def show
        group_id = params[:group_id]
        run_with_rescue do
            @redis.lock(group_id) do |lock|
                group = Group.load(group_id, @redis)
                render_success({group: group})
            end
        end
    end

    def create_test_group
        size = params[:size].to_i
        run_with_rescue do
            group = Group.new
            @redis.lock(group.id) do |lock|
                owner = group.join_as_owner
                group.update_character_pool(owner.id, Character.candidate_pool[0...size])
                group.assign_character(owner)
                owner.ready('owner', '')
                group.save!(@redis)
                render_success({group: group.render, player: owner.render_self})
            end
        end
    end
end
