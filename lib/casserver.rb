require 'active_record'
require 'active_support'
require 'builder' # for XML views
require 'logger'
$LOG = Logger.new(STDOUT)

require 'casserver/authenticators/base'

# autoload all authenticators
CASServer::Authenticators.autoload :ActiveDirectoryLDAP, 'lib/casserver/authenticators/active_directory_ldap/'
CASServer::Authenticators.autoload :LDAP, 'lib/casserver/authenticators/ldap.rb'
CASServer::Authenticators.autoload :SQL, 'lib/casserver/authenticators/sql.rb'
CASServer::Authenticators.autoload :SQLEncrypted, 'lib/casserver/authenticators/sql_encrypted.rb'
CASServer::Authenticators.autoload :Google, 'lib/casserver/authenticators/google.rb'
CASServer::Authenticators.autoload :Test, 'lib/casserver/authenticators/test.rb'

require 'casserver/server'
require 'casserver/api'
