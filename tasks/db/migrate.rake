namespace :db do
  desc "bring your CAS server database schema up to date"
  task :migrate do |t|
    $:.unshift File.dirname(__FILE__) + "/../../lib"
    
    require 'casserver/server'
    
    CASServer::Model::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.migrate("db/migrate")
  end
end
