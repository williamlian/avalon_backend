class PlayerController < ApplicationController

    def status
        player_id = params[:player_id]
        group_id = Player.find_group_id_by_player_id(player_id)
        if !group_id.nil?
            begin
                group = Group.load_for_read(group_id) do |group|
                    player = group.players[player_id]
                    if !player.nil?
                        return render_success({
                            group: group.player_view(player),
                            player: player.render_self
                        })
                    end
                end
            rescue => e
                puts "error getting player status: " + e.to_s
                puts e.backtrace.join("\n")
            end
        end
        Player.remove_player(player_id)
        render_success({group: nil, player: nil})
    end

    def delete
        player_id = params[:player_id]
        group_id = Player.find_group_id_by_player_id(player_id)
        puts "trying to delete #{player_id} from #{group_id}"
        remove_player = false
        remove_group = false
        if group_id.nil?
            remove_player = true
            puts "group not found for #{player_id}"
        else
            begin
                group = Group.load_for_read(group_id) do |group|
                    player = group.players[player_id]
                    if player.nil?
                        remove_player = true
                        puts "player #{player_id} not in group #{group_id}"
                    elsif !player.is_admin
                        puts "removing normal player #{player_id}"
                        group.remove_player(player)
                        remove_player = true
                        group.save!
                        return render_success({})
                    else
                        # admin
                        puts "removing group #{group_id}"
                        remove_player = true
                        remove_group = true
                    end
                end
            rescue => e
                puts "error removing player: " + e.to_s
                puts e.backtrace.join("\n")
            end
        end
        Player.remove_player(player_id) if remove_player
        Group.remove(group_id) if remove_group
        render_success({})
    end
end
