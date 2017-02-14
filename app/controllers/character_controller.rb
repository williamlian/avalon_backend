class CharacterController < ApplicationController

	def index
		characters = Character.candidate_pool.map do |ch|
			{
				key: ch,
				name: Character::NAME_MAP[ch],
				side: Character::SIDE_MAP[ch]
			}
		end
		render_success({characters: characters})
	end

end
