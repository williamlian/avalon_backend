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
end
