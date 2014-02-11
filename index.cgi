#!/usr/bin/ruby

$:.unshift(File.dirname(__FILE__).untaint)

require 'rubygems'
require 'bundler/setup'
require 'rack'

require 'lib/app'

Rack::Handler::CGI.run(Application.new)
