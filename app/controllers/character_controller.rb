class CharacterController < ApplicationController

	def index
		render_success({characters: Character.candidate_pool})
	end

end
