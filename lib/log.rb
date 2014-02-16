# -*- coding: utf-8

module Log
  def self.opened?(log_file)
    defined?(@file) && @@file && !File::identical?(@@file, log_file)
  end

  def self.open(log_file)
    @@file = File.open(log_file, "a")
  end

  def self.write(log_file, *args)
    open(log_file) unless opened?(log_file)

    @@file.write "\n-------------------------------" + Time.now.inspect + "\n"
    @@file.write args.map{|x| x.to_s}.join("\n")
    @@file.write "\n"
  end
end
