class Character
    MERLIN              = 'merlin'
    PERCIVAL            = 'percival'
    ROYAL_SERVANT       = 'royal_servant'

    ASSASIN             = 'assasin'
    MORGANA             = 'morgana'
    MORDRED             = 'mordred'
    OBERON              = 'oberon'
    MINION              = 'minion'

    MERLIN_OR_MORGANA   = 'merlin_or_morgana'
    EVIL                = 'evil'
    UNKNOWN             = 'unknown'

    def self.candidate_pool
        [
            MERLIN,
            PERCIVAL,
            ROYAL_SERVANT,
            ROYAL_SERVANT,
            ROYAL_SERVANT,
            ROYAL_SERVANT,

            ASSASIN,
            MORGANA,
            MORDRED,
            OBERON,
            MINION,
            MINION,
            MINION,
            MINION
        ]
    end

    def self.validate(character)
        character.in? candidate_pool
    end

    def self.validate_list(characters)
        characters.each {|c| return false if !validate(c)}
        true
    end
end
