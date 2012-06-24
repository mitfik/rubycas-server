require 'rubygems'
require 'bundler/setup'

$:.unshift "#{File.dirname(__FILE__)}/lib"
require "casserver"

use Rack::ShowExceptions
use Rack::Runtime
use Rack::CommonLogger


run Rack::URLMap.new({
  "/" => CASServer::Server,
  "/api" => CASServer::APIServer
})
