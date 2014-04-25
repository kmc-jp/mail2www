# -*- encoding: utf-8

$:.unshift(File.dirname(__FILE__))

require 'lib/app'
require 'lib/config'

run Mail2www::App.new(Mail2www::Config.new)
