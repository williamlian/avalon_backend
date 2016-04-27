require 'json'

class GroupController < ApplicationController

    def create()
        render :json => {group: 1, size: params["size"]}
    end

end
