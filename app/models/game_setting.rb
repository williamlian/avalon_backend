class GameSetting

	GAME = [nil, nil, nil, nil, nil,
		# 5
		{
			Character::SIDE_GOOD => 3,
			Character::SIDE_EVIL => 2,
			knights: [2, 3, 2, 3, 3],
			fails: [1, 1, 1, 1, 1]
		},
		# 6
		{
			Character::SIDE_GOOD => 4,
			Character::SIDE_EVIL => 2,
			knights: [2, 3, 4, 3, 4],
			fails: [1, 1, 1, 1, 1]
		},
		# 7
		{
			Character::SIDE_GOOD => 4,
			Character::SIDE_EVIL => 3,
			knights: [2, 3, 3, 4, 4],
			fails: [1, 1, 1, 2, 1]
		},
		# 8
		{
			Character::SIDE_GOOD => 5,
			Character::SIDE_EVIL => 3,
			knights: [3, 4, 4, 5, 5],
			fails: [1, 1, 1, 2, 1]
		},
		# 9
		{
			Character::SIDE_GOOD => 6,
			Character::SIDE_EVIL => 3,
			knights: [3, 4, 4, 5, 5],
			fails: [1, 1, 1, 2, 1]
		},
		# 10
		{
			Character::SIDE_GOOD => 6,
			Character::SIDE_EVIL => 4,
			knights: [3, 4, 4, 5, 5],
			fails: [1, 1, 1, 2, 1]
		},
		# 11
		{
			Character::SIDE_GOOD => 7,
			Character::SIDE_EVIL => 4,
			knights: [3, 4, 4, 5, 5],
			fails: [1, 1, 1, 2, 1]
		},
		# 12
		{
			Character::SIDE_GOOD => 7,
			Character::SIDE_EVIL => 5,
			knights: [3, 4, 4, 5, 5],
			fails: [1, 1, 1, 2, 1]
		},
	]

	MAX_VOTE = 5
	MAX_QUEST = 5

	def self.verify_candidates(size, candidates)
		setting = GAME[size];
		sides = {
			Character::SIDE_GOOD => 0,
			Character::SIDE_EVIL => 0
		}
		candidates.each do |candidate|
			sides[Character::SIDE_MAP[candidate]] += 1
		end

		if sides[Character::SIDE_GOOD] == setting[Character::SIDE_GOOD] &&
			sides[Character::SIDE_EVIL] == setting[Character::SIDE_EVIL]
			return {valid: true}
		else
			return {
				valid: false,
				message: "need #{setting[Character::SIDE_GOOD]} good and #{setting[Character::SIDE_EVIL]} evil characters"
			}
		end
	end
end