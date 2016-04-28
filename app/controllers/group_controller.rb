require 'json'

class GroupController < ApplicationController

    def create()
    	group = Group.create(params[:size])
        run_with_rescue do
            player = group.join_as_owner()
        	group.save!
            render_success({group: group.render, player: player.render_self})
        end
    end

    def update_candidate()
        player_id = params[:player_id]
        group_id = params[:group_id]
        candidates = params[:candidates]

        run_with_rescue do 
            if !Character.validate_list(candidates)
                raise 'not valid character pool'
            end
            group = Group.load(group_id)
            group.update_character_pool(player_id, candidates)
            group.save!
            render_success
        end
    end

    def join()
        group_id = params[:group_id]
        run_with_rescue do
            group = Group.load(group_id)
            player = group.join_as_player
            group.save!
            render_success({player: player.render_self})
        end
    end

    def show()
        group_id = params[:group_id]
        run_with_rescue do
            group = Group.load(group_id)
            puts group.to_json
            render_success({group: group.render})
        end
    end

    def ready
        player_id = params[:player_id]
        group_id = params[:group_id]
        name = params[:name]
        photo = params[:photo]
        run_with_rescue do 
            group = Group.load(group_id)
            if !group.has_player?(player_id)
                raise 'player not found'
            end
            player = group.players[player_id]
            if player.is_read
                raise 'player is ready'
            end
            player.name = name
            player.photo = photo
            group.assign_character(player)
            player.is_ready = true
            group.save!
            render_success({player: player})
        end
    end
end
