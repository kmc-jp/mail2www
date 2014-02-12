# -*- coding: utf-8

$:.unshift(File.dirname(__FILE__))

require 'config'

module Log
  def self.open
    @@file = File.open(Config::LOGFILE, "a")
  end

  def self.write(*args)
    open unless defined?(@@file) && @@file

    @@file.write "\n-------------------------------" + Time.now.inspect + "\n"
    @@file.write args.map{|x| x.to_s}.join("\n")
    @@file.write "\n"
  end
end

