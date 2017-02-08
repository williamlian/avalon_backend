require "rails_helper"
require 'json'

describe GroupController do
    
    before(:each) do
        @characters = ["merlin","percival","assassin","morgana","royal_servant","mordred","oberon","minion"]
        @size = 8
    end
    
    describe 'create' do
        it "should succeed" do
            post :create, {size: @size, format: :json}
            expect(response.status).to eq(200)
            json = JSON.parse(response.body)
            expect(json['group']['size']).to eq(@size)
            expect(json['player']['is_admin']).to eq(true)
        end
    end
    
    describe 'update_characters' do
        it "should succeed" do
            group = make_sample_group
            expect(response.status).to eq(200)
            expect(group["success"]).to eq(true)
            expect(group["group"]["character_pool"]).to match_array(@characters)
        end
    end
    
    describe 'join' do
        it "should add player" do
           group = make_sample_group
           post :join, {group_id: group["group"]["id"]}
           player = JSON.parse(response.body)
           
           expect(player["group"]["player_count"]).to eq(2)
           expect(player["player"]["id"]).not_to eq(group["group"]["owner"]) 
           expect(player["player"]["is_admin"]).to eq(false)
        end
    end
    
    describe 'ready' do
        it 'should make the first player ready' do
            group = make_sample_group
            post :ready, {
                player_id: group["group"]["owner"],
                name: "Someone",
                photo: "Foo"
            }
            group = JSON.parse(response.body)
            player = group["player"]
            
            expect(player["name"]).to eq("Someone")
            expect(player["photo"]).to eq("Foo")
            expect(player["is_ready"]).to eq(true)
            expect(player["character"]).not_to be_empty
            expect(group["group"]["status"]).to eq("open")
        end
        
        it "should start game if every one is ready" do
            group = make_ready_group
            
            expect(group["group"]["status"]).to eq(Group::GROUP_STATE_STARTED)
            players = group["group"]["players"]
            players.each do |id, player|
                expect(player["is_ready"]).to be true
            end
            names = players.map {|id, player| player["name"]}
            photos = players.map{|id, player| player["photo"]}
            characters = players.map{|id, player| player["character"]}
            king = players.map{|id, player| player["is_king"]}
            sequence = players.map{|id, player| player["player_sequence"]}
            
            expect(names).to match_array((0...@size).map{|i| "Player-#{i}"})
            expect(photos).to match_array((0...@size).map{|i| "Foo-#{i}"})
            expect(characters).to match_array(@characters)
            expect(king.find_all{|x| x}.length).to eq(1)
            expect(sequence).to match_array((0...@size).to_a)
        end
    end
    
    describe 'player_view' do
        it "merlin: should show masked characters" do
            group = make_ready_group
            view_as = 'merlin'
            
            check_character_mask(group, view_as, 'merlin', 'merlin')
            check_character_mask(group, view_as, 'percival', 'unknown')
            check_character_mask(group, view_as, 'assassin', 'evil')
            check_character_mask(group, view_as, 'morgana', 'evil')
            check_character_mask(group, view_as, 'royal_servant', 'unknown')
            check_character_mask(group, view_as, 'mordred', 'unknown')
            check_character_mask(group, view_as, 'oberon', 'evil')
            check_character_mask(group, view_as, 'minion', 'evil')
        end
        
        it "percival: should show masked characters" do
            group = make_ready_group
            view_as = 'percival'
            
            check_character_mask(group, view_as, 'merlin', 'merlin_or_morgana')
            check_character_mask(group, view_as, 'percival', 'percival')
            check_character_mask(group, view_as, 'assassin', 'unknown')
            check_character_mask(group, view_as, 'morgana', 'merlin_or_morgana')
            check_character_mask(group, view_as, 'royal_servant', 'unknown')
            check_character_mask(group, view_as, 'mordred', 'unknown')
            check_character_mask(group, view_as, 'oberon', 'unknown')
            check_character_mask(group, view_as, 'minion', 'unknown')
        end
        
        it "assassin: should show masked characters" do
            group = make_ready_group
            view_as = 'assassin'
            
            check_character_mask(group, view_as, 'merlin', 'unknown')
            check_character_mask(group, view_as, 'percival', 'unknown')
            check_character_mask(group, view_as, 'assassin', 'assassin')
            check_character_mask(group, view_as, 'morgana', 'evil')
            check_character_mask(group, view_as, 'royal_servant', 'unknown')
            check_character_mask(group, view_as, 'mordred', 'evil')
            check_character_mask(group, view_as, 'oberon', 'unknown')
            check_character_mask(group, view_as, 'minion', 'evil')
        end
        
        it "morgana: should show masked characters" do
            group = make_ready_group
            view_as = 'morgana'
            
            check_character_mask(group, view_as, 'merlin', 'unknown')
            check_character_mask(group, view_as, 'percival', 'unknown')
            check_character_mask(group, view_as, 'assassin', 'evil')
            check_character_mask(group, view_as, 'morgana', 'morgana')
            check_character_mask(group, view_as, 'royal_servant', 'unknown')
            check_character_mask(group, view_as, 'mordred', 'evil')
            check_character_mask(group, view_as, 'oberon', 'unknown')
            check_character_mask(group, view_as, 'minion', 'evil')
        end
        
        it "royal_servant: should show masked characters" do
            group = make_ready_group
            view_as = 'royal_servant'
            
            check_character_mask(group, view_as, 'merlin', 'unknown')
            check_character_mask(group, view_as, 'percival', 'unknown')
            check_character_mask(group, view_as, 'assassin', 'unknown')
            check_character_mask(group, view_as, 'morgana', 'unknown')
            check_character_mask(group, view_as, 'royal_servant', 'unknown')
            check_character_mask(group, view_as, 'mordred', 'unknown')
            check_character_mask(group, view_as, 'oberon', 'unknown')
            check_character_mask(group, view_as, 'minion', 'unknown')
        end
        
        it "mordred: should show masked characters" do
            group = make_ready_group
            view_as = 'mordred'
            
            check_character_mask(group, view_as, 'merlin', 'unknown')
            check_character_mask(group, view_as, 'percival', 'unknown')
            check_character_mask(group, view_as, 'assassin', 'evil')
            check_character_mask(group, view_as, 'morgana', 'evil')
            check_character_mask(group, view_as, 'royal_servant', 'unknown')
            check_character_mask(group, view_as, 'mordred', 'mordred')
            check_character_mask(group, view_as, 'oberon', 'unknown')
            check_character_mask(group, view_as, 'minion', 'evil')
        end
        
        it "oberon: should show masked characters" do
            group = make_ready_group
            view_as = 'oberon'
            
            check_character_mask(group, view_as, 'merlin', 'unknown')
            check_character_mask(group, view_as, 'percival', 'unknown')
            check_character_mask(group, view_as, 'assassin', 'unknown')
            check_character_mask(group, view_as, 'morgana', 'unknown')
            check_character_mask(group, view_as, 'royal_servant', 'unknown')
            check_character_mask(group, view_as, 'mordred', 'unknown')
            check_character_mask(group, view_as, 'oberon', 'oberon')
            check_character_mask(group, view_as, 'minion', 'unknown')
        end
        
        it "minion: should show masked characters" do
            group = make_ready_group
            view_as = 'minion'
            
            check_character_mask(group, view_as, 'merlin', 'unknown')
            check_character_mask(group, view_as, 'percival', 'unknown')
            check_character_mask(group, view_as, 'assassin', 'evil')
            check_character_mask(group, view_as, 'morgana', 'evil')
            check_character_mask(group, view_as, 'royal_servant', 'unknown')
            check_character_mask(group, view_as, 'mordred', 'evil')
            check_character_mask(group, view_as, 'oberon', 'unknown')
            check_character_mask(group, view_as, 'minion', 'evil')
        end
    end
    
    describe "start_vote" do
        it "should start a vote" do 
            group = make_ready_group
            king = group["group"]["players"].values.find{|player| player["is_king"]}
            post :start_vote, {player_id: king["id"], knights: ["1","3","5"]}
            get :show, {group_id: group["group"]["id"]}
            group = JSON.parse(response.body)
            
            (0...@size).each do |ps|
                player = group["group"]["players"].values.find{|player| player["player_sequence"] == ps}
                if [1, 3, 5].include? ps
                    expect(player["is_knight"]).to be true
                else
                    expect(player["is_knight"]).to be false
                end
            end     
        end
    end
    
    describe "vote" do
        it "should pass when vote success" do
        end
        
        it "should rejct when vote fail" do
        end 
    end
    
    describe "start_quest" do
    end
    
    describe "end_turn" do
    end
    
    describe "submit_quest" do
    end
            
    ################################################################################################
    
    def check_character_mask(group, view_as, character, mask)
        players = group["group"]["players"].map{|id, player| [player["character"], player]}.to_h
        get :player_view, {player_id: players[view_as]["id"]}
        view = JSON.parse(response.body)
        player_view = view["group"]["players"].map{|player| [player["player_sequence"], player]}.to_h
        expect(player_view[players[character]["player_sequence"]]["character"]).to eq mask
    end
    
    def make_sample_group
        post :create, {size: @size, format: :json}
        group = JSON.parse(response.body)
        group_id = group["group"]["id"]
        admin_id = group["player"]["id"]
        post :update_characters, {
            group_id: group_id,
            player_id: admin_id,
            characters: @characters
        }
        get :show, {group_id: group_id}
        JSON.parse(response.body)
    end
    
    def make_ready_group
        group = make_sample_group
        post :ready, {
            player_id: group["group"]["owner"],
            name: "Player-0",
            photo: "Foo-0"
        }
        (1...@size).each do |i|
            post :join, {group_id: group["group"]["id"]}
            player = JSON.parse(response.body)
            post :ready, {
                player_id: player["player"]["id"],
                name: "Player-#{i}",
                photo: "Foo-#{i}"
            }
        end
        get :show, {group_id: group["group"]["id"]}
        JSON.parse(response.body)
    end
        
end
