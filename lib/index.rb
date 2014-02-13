# -*- coding: utf-8

require_relative 'config'

class Index
  include Config

  def initialize(folder)
    index_file = File.join(MAIL_DIR, folder, INDEX_FILE)
    if not File.exists? index_file
      @file = File.open(index_file, "w")
      @file.chmod(PERM_FILES)
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
