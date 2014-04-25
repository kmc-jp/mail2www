# -*- coding: utf-8

class Index
  def initialize(config, folder)
    @config = config

    index_file = File.join(@config[:mail_dir], folder, @config[:index_file])
    if !File.exist? index_file
      @file = File.open(index_file, 'w')
      while @file.flock(File::LOCK_EX | File::LOCK_NB) != 0
        sleep 1
      end
      @file.chmod(@config[:perm_files])
      @index = 0
    else
      @file = File.open(index_file, 'r+')
      while @file.flock(File::LOCK_EX | File::LOCK_NB) != 0
        sleep 1
      end
      @index = @file.read.to_i
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
