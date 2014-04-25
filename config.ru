# -*- encoding: utf-8

$:.unshift(File.dirname(__FILE__))

require 'lib/app'
require 'lib/config'

run Application.new(Mail2www::Config.new)
