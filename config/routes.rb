Rails.application.routes.draw do

    scope '/api' do
        ############################################################
        # Game Setup APIs
        ############################################################
        # post {size: int}
        # response: {group: Group, player: Player}
        post '/group' => 'group#create'

        # post {player_id: int, characters: Character[]}
        # response: {}
        post '/group/:group_id/characters' => 'group#update_characters'

        # response: {group: Group, player: Player(self rendered)}
        post '/group/:group_id/join' => 'group#join'

        # character list
        # response {characters: Character[]}
        get '/characters' => 'character#index'

        ############################################################
        # Player Status Calls
        ############################################################
        # ?player_id=uuid
        # response {group: Group (character masked by player), player: Player}
        get '/player_view' => 'group#player_view'
        
        get '/subscribe/:player_id' => 'push#subscribe'

        get '/unsubscribe/:player_id' => 'push#unsubscribe'

        ############################################################
        # Game Actions
        ############################################################

        # post {player_id: uuid, name:string, photo: base64 string}
        # response {player: Player (self rendered)}
        post '/ready' => 'group#ready'

        # same as start_vote but does not start the vote
        # post {player_id: uuid, knights: [player sequences]}
        post '/nominate' => 'group#nominate'

        # king start a vote, knights will be the last nominated knights
        # post {player_id: uuid}
        post '/start_vote' => 'group#start_vote'

        # post {player_id: uuid, vote: bool}
        # response {}
        post '/vote' => 'group#vote'

        # start the quest with selected knights, only king can start with a successful vote
        # post {player_id: uuid}
        post '/start_quest' => 'group#start_quest'

        # end the current king's turn and move king to next, only king can call with a rejected vote
        # post {player_id: uuid}
        post '/end_turn' => 'group#end_turn'

        # post {player_id: uuid, quest_result: bool}
        post '/submit_quest' => 'group#submit_quest'
        
        ############################################################
        # Misc
        ############################################################
        # abandon group, only owner can call
        post '/abandon' => 'group#abandon'

        # DEBUG ONLY
        get '/admin/group/:group_id' => 'group#show'
        get '/admin/delete/:group_id' => 'group#delete'
    end  
end
