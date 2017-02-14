class Character
    MERLIN              = 'merlin'
    PERCIVAL            = 'percival'
    ROYAL_SERVANT       = 'royal_servant'

    ASSASSIN            = 'assassin'
    MORGANA             = 'morgana'
    MORDRED             = 'mordred'
    OBERON              = 'oberon'
    MINION              = 'minion'

    MERLIN_OR_MORGANA   = 'merlin_or_morgana'
    EVIL                = 'evil'
    UNKNOWN             = 'unknown'

    VIEW_MAP = {
        MERLIN => {
            MERLIN          => MERLIN,
            PERCIVAL        => UNKNOWN,
            ROYAL_SERVANT   => UNKNOWN,
            ASSASSIN        => EVIL,
            MORGANA         => EVIL,
            MORDRED         => UNKNOWN,
            OBERON          => EVIL,
            MINION          => EVIL
        },
        PERCIVAL => {
            MERLIN          => MERLIN_OR_MORGANA,
            PERCIVAL        => PERCIVAL,
            ROYAL_SERVANT   => UNKNOWN,
            ASSASSIN        => UNKNOWN,
            MORGANA         => MERLIN_OR_MORGANA,
            MORDRED         => UNKNOWN,
            OBERON          => UNKNOWN,
            MINION          => UNKNOWN
        },
        ROYAL_SERVANT => {
            MERLIN          => UNKNOWN,
            PERCIVAL        => UNKNOWN,
            ROYAL_SERVANT   => UNKNOWN,
            ASSASSIN        => UNKNOWN,
            MORGANA         => UNKNOWN,
            MORDRED         => UNKNOWN,
            OBERON          => UNKNOWN,
            MINION          => UNKNOWN
        },
        ASSASSIN => {
            MERLIN          => UNKNOWN,
            PERCIVAL        => UNKNOWN,
            ROYAL_SERVANT   => UNKNOWN,
            ASSASSIN        => ASSASSIN,
            MORGANA         => EVIL,
            MORDRED         => EVIL,
            OBERON          => UNKNOWN,
            MINION          => EVIL
        },
        MORGANA => {
            MERLIN          => UNKNOWN,
            PERCIVAL        => UNKNOWN,
            ROYAL_SERVANT   => UNKNOWN,
            ASSASSIN        => EVIL,
            MORGANA         => MORGANA,
            MORDRED         => EVIL,
            OBERON          => UNKNOWN,
            MINION          => EVIL
        },
        MORDRED => {
            MERLIN          => UNKNOWN,
            PERCIVAL        => UNKNOWN,
            ROYAL_SERVANT   => UNKNOWN,
            ASSASSIN        => EVIL,
            MORGANA         => EVIL,
            MORDRED         => MORDRED,
            OBERON          => UNKNOWN,
            MINION          => EVIL
        },
        OBERON => {
            MERLIN          => UNKNOWN,
            PERCIVAL        => UNKNOWN,
            ROYAL_SERVANT   => UNKNOWN,
            ASSASSIN        => UNKNOWN,
            MORGANA         => UNKNOWN,
            MORDRED         => UNKNOWN,
            OBERON          => OBERON,
            MINION          => UNKNOWN
        },
        MINION => {
            MERLIN          => UNKNOWN,
            PERCIVAL        => UNKNOWN,
            ROYAL_SERVANT   => UNKNOWN,
            ASSASSIN        => EVIL,
            MORGANA         => EVIL,
            MORDRED         => EVIL,
            OBERON          => UNKNOWN,
            MINION          => EVIL
        }
    }

    SIDE_GOOD = 'good'
    SIDE_EVIL = 'evil'
    SIDE_MAP = {
        MERLIN => SIDE_GOOD,
        PERCIVAL => SIDE_GOOD,
        ROYAL_SERVANT => SIDE_GOOD,
        ASSASSIN => SIDE_EVIL,
        MORGANA => SIDE_EVIL,
        MORDRED => SIDE_EVIL,
        OBERON => SIDE_EVIL,
        MINION => SIDE_EVIL
    }

    NAME_MAP = {
        MERLIN => 'Merlin',
        PERCIVAL => 'Percival',
        ROYAL_SERVANT => 'Royal Servant of Arthur',
        ASSASSIN => 'Assassin',
        MORGANA => 'Morgana',
        MORDRED => 'Mordred',
        OBERON => 'Oberon',
        MINION => 'Minion of Mordred'
    }

    def self.candidate_pool
        [
            MERLIN,
            PERCIVAL,
            ROYAL_SERVANT,
            ROYAL_SERVANT,
            ROYAL_SERVANT,
            ROYAL_SERVANT,

            ASSASSIN,
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
        if characters.nil?
            return false
        end
        characters.each {|c| return false if !validate(c)}
        true
    end
end
