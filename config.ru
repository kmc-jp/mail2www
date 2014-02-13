# -*- encoding: utf-8

$:.unshift(File.dirname(__FILE__))

require 'lib/app'

use Rack::Static, :urls => ["/css"], :root => "./"
use Rack::ContentType
run Application.new
