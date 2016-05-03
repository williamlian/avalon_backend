Rails.application.routes.draw do

  scope '/api' do
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
    post '/group/:group_id/ready' => 'group#ready'

    # ?player_id=uuid
    # response {group: Group (character masked by player), player: Player}
    get '/group/:group_id/player_view' => 'group#player_view'

    # character list
    # response {characters: Character[]}
    get '/characters' => 'character#index'

    # periodical ping
    get '/status' => 'player#status'

    # player quit
    delete '/player/:player_id' => 'player#delete'

    # king start a vote
    post '/group/:group_id/start_vote' => 'group#start_vote'

    # post {player_id: uuid, vote: bool}
    # response {}
    post '/group/:group_id/vote' => 'group#vote'

    # start the quest with selected knights
    # post {player_id: uuid}
    post '/group/:group_id/start_quest' => 'group#start_quest'

    # end the current king's turn and move king to next
    # post {player_id: uuid}
    post '/group/:group_id/end_turn' => 'group#end_turn'

    # post {player_id: uuid, quest_result: bool}
    post '/group/:group_id/submit_quest' => 'group#submit_quest'

    # DEBUG ONLY
    get '/admin/group/:group_id' => 'group#show'
    get '/admin/test_group' => 'group#create_test_group'
  end

end
