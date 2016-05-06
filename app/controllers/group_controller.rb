require 'json'

class GroupController < ApplicationController

    def create
        run_with_rescue do
            Group.create(params[:size]) do |group|
                player = group.join_as_owner
                group.save!
                render_success({group: group.render, player: player.render_self})
            end
        end
    end

    def update_characters
        player_id = params[:player_id]
        group_id = params[:group_id]
        candidates = params[:characters]

        run_with_rescue do 
            if !Character.validate_list(candidates)
                raise 'not valid character pool'
            end
            Group.load_for_update(group_id) do |group|
                group.update_character_pool(player_id, candidates)
                group.save!
                player = group.players[player_id]
                render_success({group: group.render, player: player.render_self})
            end
        end
    end

    def join
        group_id = params[:group_id]
        run_with_rescue do
            Group.load_for_update(group_id) do |group|
                player = group.join_as_player
                group.save!
                render_success({group: group.render, player: player.render_self})
            end
        end
    end

    def ready
        player_id = params[:player_id]
        group_id = params[:group_id]
        name = params[:name]
        photo = params[:photo]
        run_with_rescue do 
            Group.load_for_update(group_id) do |group|
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
                group.save!
                render_success({group: group.render, player: player.render_self})
            end
        end
    end

    def player_view
        player_id = params[:player_id]
        group_id = params[:group_id]
        run_with_rescue do
            Group.load_for_read(group_id) do |group|
                if !group.has_player?(player_id)
                    raise 'player not found'
                end
                player = group.players[player_id]
                if !player.is_ready
                    raise 'player is not ready'
                end
                if group.status == Group::GROUP_STATE_CREATED
                    raise 'group is not open yet'
                end
                render_success({group: group.player_view(player), player: player.render_self})
            end
        end
    end

    # knights is a list of user sequences
    def start_vote
        group_id = params[:group_id]
        player_id = params[:player_id]
        knights = params[:knights].map{|x|x.to_i}
        run_with_rescue do
            Group.load_for_update(group_id) do |group|
                if group.status == Group::GROUP_STATE_VOTING
                    raise 'voting is already started'
                elsif group.status != Group::GROUP_STATE_STARTED
                    raise 'game is not started yet'
                end
                player = group.players[player_id]
                if !player.is_king
                    raise 'only king can start voting'
                end
                group.start_vote(knights)
                group.save!
                render_success({})
            end
        end
    end

    def vote
        group_id = params[:group_id]
        player_id = params[:player_id]
        vote = params[:vote]
        run_with_rescue do
            Group.load_for_update(group_id) do |group|
                if group.status != Group::GROUP_STATE_VOTING
                    raise 'voting is not acceptable currently'
                end
                player = group.players[player_id]
                unless player.last_vote.nil?
                    raise 'you voted already'
                end
                player.last_vote = vote
                group.check_vote
                group.save!
                render_success({})
            end
        end
    end

    def start_quest
        group_id = params[:group_id]
        player_id = params[:player_id]
        run_with_rescue do
            Group.load_for_update(group_id) do |group|
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
                group.save!
                render_success({})
            end
        end
    end

    def end_turn
        group_id = params[:group_id]
        player_id = params[:player_id]
        run_with_rescue do
            Group.load_for_update(group_id) do |group|
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
                group.save!
                render_success({})
            end
        end
    end

    def submit_quest
        group_id = params[:group_id]
        player_id = params[:player_id]
        quest_result = params[:quest_result]
        run_with_rescue do
            Group.load_for_update(group_id) do |group|
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
                group.save!
                render_success({})
            end
        end
    end

    def checkpoint
        group_id = params[:group_id]
        run_with_rescue do
            ts = Group.get_timestamp(group_id)
            render_success({last_updated_on: ts})
        end
    end

    # admin function
    def show
        group_id = params[:group_id]
        run_with_rescue do
            Group.load_for_read(group_id) do |group|
                puts group.to_json
                render_success({group: group})
            end
        end
    end

    def create_test_group
        size = params[:size].to_i
        run_with_rescue do
            Group.create(size) do |group|
                owner = group.join_as_owner
                group.update_character_pool(owner.id, Character.candidate_pool[0...size])
                group.assign_character(owner)
                owner.ready('owner', '')
                group.save!
                render_success({group: group.render, player: owner.render_self})
            end
        end
    end
end
