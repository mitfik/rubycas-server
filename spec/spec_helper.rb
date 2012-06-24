ENV['RACK_ENV'] = "test"

require 'rubygems'
require 'sinatra'
require 'rack/test'
require 'rspec'
require 'logger'
require 'ostruct'

require 'capybara'
require 'capybara/dsl'
require 'casserver/authenticators/base'

# autoload all authenticators
CASServer::Authenticators.autoload :ActiveDirectoryLDAP, 'lib/casserver/authenticators/active_directory_ldap/'
CASServer::Authenticators.autoload :LDAP, 'lib/casserver/authenticators/ldap.rb'
CASServer::Authenticators.autoload :SQL, 'lib/casserver/authenticators/sql.rb'
CASServer::Authenticators.autoload :Google, 'lib/casserver/authenticators/google.rb'
CASServer::Authenticators.autoload :Test, 'lib/casserver/authenticators/test.rb'

# set test environment
set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false

#if Dir.getwd =~ /\/spec$/
#  # Avoid potential weirdness by changing the working directory to the CASServer root
#  FileUtils.cd('..')
#end

# TODO: check and remove
# Ugly monkeypatch to allow us to test for correct redirection to
# external services.
#
# This will likely break in the future when Capybara or RackTest are upgraded.
#class Capybara::Driver::RackTest
#  def current_url
#    if @redirected_to_external_url
#      @redirected_to_external_url
#    else
#      request.url rescue ""
#    end
#  end
#
#  def follow_redirects!
#    if response.redirect? && response['Location'] =~ /^http[s]?:/
#      @redirected_to_external_url = response['Location']
#    else
#      5.times do
#        follow_redirect! if response.redirect?
#      end
#      raise Capybara::InfiniteRedirectError, "redirected more than 5 times, check for infinite redirects." if response.redirect?
#    end
#  end
#end

# This called in specs' `before` block.
# Due to the way Sinatra applications are loaded,
# we're forced to delay loading of the server code
# until the start of each test so that certain 
# configuraiton options can be changed (e.g. `uri_path`)
def load_server(app)
  
  app.enable(:raise_errors)
  app.disable(:show_exceptions)
  #Capybara.current_driver = :selenium
  Capybara.app = app
end

# Deletes the database specified in the app's config
# and runs the migrations to rebuild the database schema.
def reset_spec_database(app)
  raise "Cannot reset the spec database because config[:database][:database] is not defined." unless
    app.settings.database && app.settings.database[:database]

  ActiveRecord::Base.establish_connection(app.settings.database)
  case app.settings.database[:adapter]
  when /sqlite/
    require 'pathname'
    path = Pathname.new(app.settings.database[:database])
    file = path.absolute? ? path.to_s : File.join(app.settings.root, '..', '..', path)

    FileUtils.rm(file) if File.exist?(file)
  else 
    ActiveRecord::Base.connection.drop_database app.settings.database[:database]
  end

  ActiveRecord::Base.logger = Logger.new(STDOUT)
  ActiveRecord::Base.logger.level = Logger::ERROR
  ActiveRecord::Migration.verbose = false
  ActiveRecord::Migrator.migrate("db/migrate")
end



