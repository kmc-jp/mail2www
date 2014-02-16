# -*- encoding: utf-8

$:.unshift(File.dirname(__FILE__))

require 'lib/app'
require 'lib/config'

use Rack::Static, :urls => ["/css"], :root => "./"
use Rack::ContentType, "text/html; charset=utf-8"
run Application.new(Mail2www::Config.new)
