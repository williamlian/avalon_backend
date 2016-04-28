Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # post {size: int}
  # response: {group: Group, player: Player}
  post '/new_group' => 'group#create'

  # post {player_id: int, group_id: int, candidates: Character[]}
  # response: {}
  post '/update_candidate' => 'group#update_candidate'

  # response: {group: Group, player: Player(self rendered)}
  post '/group/:group_id/join' => 'group#join'

  # post {group_id: uuid, name:string, photo: base64 string}
  # response {player: Player (self rendered)}
  post '/player/:player_id/ready' => 'group#ready'

  get '/group/:group_id' => 'group#show'


  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase
end
