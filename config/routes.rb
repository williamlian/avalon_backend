Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

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
  # response {group: Group (character masked by player)}
  get '/group/:group_id/player_view' => 'group#player_view'


  # DEBUG ONLY
  get '/group/:group_id' => 'group#show'


  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase
end
