#!/usr/bin/env ruby
#
# add.rb - add a new mail and refile it#
#

UNDER_MAINTENANCE = false
if UNDER_MAINTENANCE
  MAINTENANCE_DIR = "maintenance"
  Dir.mkdir(MAINTENANCE_DIR) unless File.directory?(MAINTENANCE_DIR)

  k = 0
  k += 1 while File.exist?(File.expand_path(k.to_s, MAINTENANCE_DIR))

  exit
end

$:.unshift(File.dirname(__FILE__))
require 'mails'

begin
  mail = ARGF.read
  Mails.new.add(mail)
rescue Exception => e
  Log.write e.message, e.backtrace.join("\n")
end
