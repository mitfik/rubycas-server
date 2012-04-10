require 'sinatra/base'
require 'sinatra/config_file'
require 'sinatra/r18n'

module CASServer 
  class Base < Sinatra::Base
    register Sinatra::ConfigFile
    register Sinatra::R18n

    set :default_locale, 'en'
    set :translations,   './locales'

    config_file '../../config/config.yml'

    # default configuration
    set :maximum_unused_login_ticket_lifetime, 5.minutes
    set :maximum_unused_service_ticket_lifetime, 5.minutes # CAS Protocol Spec, sec. 3.2.1 (recommended expiry time)
    set :maximum_session_lifetime, 2.days # all tickets are deleted after this period of time
    set :log, {:file => 'casserver.log', :level => 'DEBUG'}
    set :uri_path,  ""
    set :server, 'webrick'
  end
end

