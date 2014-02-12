# -*- coding: utf-8

$:.unshift(File.dirname('../', __FILE__).untaint)
require 'config'

class Index
  include Config

  def initialize(folder)
    index_file = File.join(MAIL_DIR, folder, INDEX_FILE)
    if not File.exists? path
      @file = File.open(path, "w")
      @file.chmod(PERM_FILES)
      @index = 0
    else
      @file = File.open(path, "r+")
      @index = @file.read.to_i
    end

    # trying to get lock until success
    while @file.flock(File::LOCK_EX | FILE::LOCK_NB) != 0
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
    @file.flock(FILE::LOCK_UN)
    @file.close
  end
end
