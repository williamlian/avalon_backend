module FileLock
    # open a file with read lock and yield a block with the file descriptor
    def with_read_lock(file_name)
        File.open(file_name, "r") do |f|
            f.flock(File::LOCK_SH)
            begin
                yield f
            rescue => e
                f.flock(File::LOCK_UN)
                raise e
            end
        end
    end

    # open a file with write lock and yield a block with the file descriptor
    def with_update_lock(file_name)
        # make sure the folder is there
        dir = File.dirname(file_name)
        FileUtils.mkdir_p(dir)
        # Obtain exclusive lock to prevent write correction
        File.open(file_name, File::RDWR|File::CREAT, 0644) do |f|
            f.flock(File::LOCK_EX)
            begin
                yield f
            rescue => e
                f.flock(File::LOCK_UN)
                raise e
            end
        end
    end

end
