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
            group = make_voting_group
            
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
        it "should mark user as voted" do
            group = make_voting_group
            player = group["group"]["players"].values.find{|p| p["player_sequence"] == 1}
            
            post :vote, {player_id: player["id"], vote: false}
            get :show, {group_id: group["group"]["id"]}
            group = JSON.parse(response.body)
            player = group["group"]["players"].values.find{|p| p["player_sequence"] == 1}
            
            expect(player["last_vote"]).to be false
        end
        
        it "should pass when vote success" do
            group = make_voted_group(@size / 2 + 1)
            
            expect(group["group"]["last_vote_result"]).to be true
        end
        
        it "should rejct when vote fail" do
            group = make_voted_group(@size / 2 - 1)
            
            expect(group["group"]["last_vote_result"]).to be false
        end 
    end
    
    describe "start_quest" do
        it "should put group into quest state" do
            group = make_voted_group(@size)
            king = group["group"]["players"].values.find{|p| p["is_king"]}
            
            post :start_quest, {player_id: king["id"]}
            get :show, {group_id: group["group"]["id"]}
            group = JSON.parse(response.body)
            knights = group["group"]["players"].values.select{|p| p["is_knight"]}
            
            expect(group["group"]["status"]).to eq Group::GROUP_STATE_QUEST
            knights.each do |knight|
                expect(knight["status"]).to eq Player::PLAYER_STATE_QUEST
            end
        end
        
        it "should not start quest when vote is not completed" do
            group = make_voting_group
            
            king = group["group"]["players"].values.find{|p| p["is_king"]}
            post :start_quest, {player_id: king["id"]}
            group = JSON.parse(response.body)
            
            expect(group["success"]).to be false
            expect(group["message"]).to eq "vote is not accepted"
        end
        
        it "should not start quest when vote is rejected" do
            group = make_voted_group(0)
            
            king = group["group"]["players"].values.find{|p| p["is_king"]}
            post :start_quest, {player_id: king["id"]}
            group = JSON.parse(response.body)
            
            expect(group["success"]).to be false
            expect(group["message"]).to eq "vote is not accepted"
        end
    end
    
    describe "end_turn" do
        it "should pass king to next player" do
            group = make_voted_group(0)
            
            king = group["group"]["players"].values.find{|p| p["is_king"]}
            post :end_turn, {player_id: king["id"]}
            get :show, {group_id: group["group"]["id"]}
            group = JSON.parse(response.body)
            next_king = group["group"]["players"].values.find{|p| p["is_king"]}
            
            expect(next_king["player_sequence"]).to eq ((king["player_sequence"] + 1) % @size)
            expect(group["group"]["status"]).to eq Group::GROUP_STATE_STARTED
            expect(group["group"]["last_vote_result"]).to be nil
            group["group"]["players"].values.each do |player|
                expect(player["is_knight"]).to be false
            end
        end
        
        it "should not end turn if vote is approved" do 
            group = make_voted_group(@size)
            
            king = group["group"]["players"].values.find{|p| p["is_king"]}
            post :end_turn, {player_id: king["id"]}
            group = JSON.parse(response.body)
            
            expect(group["success"]).to be false
            expect(group["message"]).to eq "vote is not rejected, please start quest"
        end
        
        it "should end the game if it is the fifth rejection" do
            #TODO
        end
    end
    
    describe "submit_quest" do
        it "should store knight's result" do
            group = make_voted_group(@size)
            king = group["group"]["players"].values.find{|p| p["is_king"]}
            knights = group["group"]["players"].values.select{|p| p["is_knight"]}
            post :start_quest, {player_id: king["id"]}
            
            post :submit_quest, {player_id: knights[0]["id"], quest_result: true}
            get :show, {group_id: group["group"]["id"]}
            group = JSON.parse(response.body)
            knights = group["group"]["players"].values.select{|p| p["is_knight"]}
            
            results = knights.map{|k| k["last_quest_result"]}
            expect(results.select{|r|r}.length).to eq 1
            expect(results.select{|r|r.nil?}.length).to eq (knights.length - 1)
        end
        
        it "should store result and switch back to start state when quest is complete" do
            group = make_voted_group(@size)
            king = group["group"]["players"].values.find{|p| p["is_king"]}
            knights = group["group"]["players"].values.select{|p| p["is_knight"]}
            post :start_quest, {player_id: king["id"]}
            
            knights.each do |knight|
                post :submit_quest, {player_id: knight["id"], quest_result: true}
            end
            get :show, {group_id: group["group"]["id"]}
            group = JSON.parse(response.body)
            next_king = group["group"]["players"].values.find{|p| p["is_king"]}
            
            expect(group["group"]["quest_result"]["success"]).to eq knights.length
            expect(group["group"]["quest_result"]["failed"]).to eq 0
            
            # next round
            expect(next_king["player_sequence"]).to eq ((king["player_sequence"] + 1) % @size)
            expect(group["group"]["status"]).to eq Group::GROUP_STATE_STARTED
            expect(group["group"]["last_vote_result"]).to be nil
            group["group"]["players"].values.each do |player|
                expect(player["is_knight"]).to be false
                expect(player["last_quest_result"]).to be nil
                expect(player["status"]).to eq Player::PLAYER_STATE_READY
            end
        end
        
        it "should mark quest as success according to rule" do
            #TODO
        end
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
    
    def make_voting_group
        group = make_ready_group
        king = group["group"]["players"].values.find{|player| player["is_king"]}
        post :start_vote, {player_id: king["id"], knights: ["1","3","5"]}
        get :show, {group_id: group["group"]["id"]}
        JSON.parse(response.body)
    end
    
    def make_voted_group(approve_count)
        group = make_voting_group
        players = group["group"]["players"].values
        (0...approve_count).each do |i|
            post :vote, {player_id: players[i]["id"], vote: true}
        end
        (approve_count...@size).each do |i|
            post :vote, {player_id: players[i]["id"], vote: false}
        end
        get :show, {group_id: group["group"]["id"]}
        JSON.parse(response.body)
    end
end
