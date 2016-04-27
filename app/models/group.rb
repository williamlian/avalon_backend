require 'uuidtools'

class Group
    attr_accessor :id, 
        :player_count, 
        :size, 
        :state, 
        :players, 
        :character_pool

    GROUP_FILE_PATH = '/var/tmp/avalon/groups/'

    GROUP_STATE_CREATED = 'created'
    GROUP_STATE_OPEN    = 'open'
    GROUP_STATE_STARTED = 'started'

    def initialize
        @id = UUIDTools::UUID.random_create.to_s
        @player_count = 0
        @size = 0
        @state = GROUP_STATE_CREATED
        @players = []
        @character_pool = []
    end

    ########################### Static Members #######################
    def self.create(size)
        group = Group.new
        group.size = size
        group
    end

    # nil means file not found
    def self.load(uuid)
        file_path = GROUP_FILE_PATH + uuid
        begin
            File.open(file_path, "r") {|f|
                f.flock(File::LOCK_SH)
                data = f.read
                return Group.from_json(JSON.parse(data))
            }
        rescue Exception => e
            return nil
        end
    end

    def self.from_json(json)
        group = Group.new
        group.id = json["id"]
        group.player_count = json["player_count"].to_i
        group.size = json["size"].to_i
        group.state = json["state"]
        if json["players"] != nil
            json["players"].each do |player|
                group.players << Player.from_json(player)
            end
        end
        group.character_pool = json["character_pool"]
        group
    end

    ############################## Members ###########################
    def file_path
        GROUP_FILE_PATH + @id
    end

    def save!
        # make sure the dir is there
        FileUtils.mkdir_p(GROUP_FILE_PATH)
        # Obtain exclusive lock to prevent write correction
        File.open(self.file_path, File::RDWR|File::CREAT, 0644) {|f|
            f.flock(File::LOCK_EX)
            f.truncate(0)
            f.write(self.to_json.to_s)
            f.flush
        }
        puts "group saved to " + self.file_path
    end

end
