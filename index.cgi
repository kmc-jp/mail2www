#!/usr/bin/ruby

$:.unshift(File.dirname(__FILE__))

require 'rubygems'
require 'bundler/setup'
require 'rack'

require 'lib/app'
require 'lib/config'

Rack::Handler::CGI.run(Application.new(Mail2www::Config.new))
