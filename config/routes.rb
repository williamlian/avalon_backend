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

        # post {player_id: uuid, name:string, photo: base64 string}
        # response {player: Player (self rendered)}
        post '/ready' => 'group#ready'
        
        # character list
        # response {characters: Character[]}
        get '/characters' => 'character#index'

        ############################################################
        # Player Status Calls
        ############################################################
        # ?player_id=uuid
        # response {group: Group (character masked by player), player: Player}
        get '/player_view' => 'group#player_view'

        ############################################################
        # Game Actions
        ############################################################

        # king start a vote
        # post {player_id: uuid, knights: [player sequences]}
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
        # player quit
        #delete '/player/:player_id' => 'player#delete'

        # DEBUG ONLY
        get '/admin/group/:group_id' => 'group#show'
        get '/admin/test_group' => 'group#create_test_group'
    end  
end
