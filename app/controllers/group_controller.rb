require 'json'

class GroupController < ApplicationController

    def create()
    	group = Group.create(params[:size])
    	group.save!
        render :json => group.to_json
    end

end
