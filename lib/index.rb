# -*- coding: utf-8

class Index

  def initialize(config, folder)
    @config = config

    index_file = File.join(@config[:mail_dir], folder, @config[:index_file])
    if not File.exists? index_file
      @file = File.open(index_file, "w")
      @file.chmod(@config[:perm_files])
      @index = 0
    else
      @file = File.open(index_file, "r+")
      @index = @file.read.to_i
    end

    # trying to get lock until success
    while @file.flock(File::LOCK_EX | File::LOCK_NB) != 0
      # failed to get lock
      sleep 1
    end
  end

  def inc
    @index += 1
  end

  def value
    @index
  end

  def close
    raise "Index#close called twice" if @file.nil?

    @file.truncate 0
    @file.rewind
    @file.write @index.to_s
    @file.flock(File::LOCK_UN)
    @file.close
  end
end
