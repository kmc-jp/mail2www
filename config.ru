# -*- encoding: utf-8

$:.unshift(File.dirname(__FILE__).untaint)

require 'lib/app'

use Rack::Static, :urls => ["/css"], :root => "./"
run Application.new
