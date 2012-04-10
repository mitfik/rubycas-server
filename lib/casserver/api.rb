require 'casserver/utils'
require 'casserver/cas'
require 'casserver/base'

require 'logger'
#$LOG ||= Logger.new(STDOUT)
$LOG = Logger.new(STDOUT)

module CASServer
  class APIServer < CASServer::Base
    # TODO change that for some CAS helpers 
    include CASServer::CAS 

    # :category: API
    # 
    # return:: Status code: 204
    get '/isalive', :provides => [:json, :xml] do
      status 204
    end

    # :category: API
    #
    # === return
    # Status:: Status code: 200, 203
    # xml:: NOT IMPLEMENTED
    # json:: {:type => "confirmation", :message => "You have successfully logged out."}
    #        {:type => "notice", :message => "Your granting ticket is invalid."}
    #        {:type => "confirmation", :service => params[:service] }
    delete "/logout", :provides => [:json, :xml] do
      @replay = {} 
      gateway = params['gateway'] == 'true'
      tgt = CASServer::Model::TicketGrantingTicket.find_by_ticket(request.cookies['tgt'])

      if tgt
        CASServer::Model::TicketGrantingTicket.transaction do
          tgt.granted_service_tickets.each do |st|
            send_logout_notification_for_service_ticket(st) if settings.enable_single_sign_out
            st.destroy
          end
          pgts = CASServer::Model::ProxyGrantingTicket.find(:all,
            :conditions => [CASServer::Model::Base.connection.quote_table_name(CASServer::Model::ServiceTicket.table_name)+".username = ?", tgt.username],
            :include => :service_ticket)
          pgts.each do |pgt|
            $LOG.debug("Deleting Proxy-Granting Ticket '#{pgt}' for user '#{pgt.service_ticket.username}'")
            pgt.destroy
          end
          $LOG.debug("Deleting #{tgt.class.name.demodulize} '#{tgt}' for user '#{tgt.username}'")
          tgt.destroy
        end

        $LOG.info("User '#{tgt.username}' logged out.")
        @replay[:type] = "confirmation"
        @replay[:message] = t.notice.successfull_logged_out
        status 200
      else
        @replay[:type] = "notice"
        @replay[:message] = t.error.invalid_granting_ticket
        status 203
      end
      prepare_replay_for(request)
    end

    # :category: API
    # 
    # return:: Status code: 201, 404, 401
    post "/login", :provides => [:json, :xml] do
      @replay = {} 
      service = clean_service_url(params['service'])
      username = params['username'].to_s.strip
      password = params['password']
      
      username.downcase! if username && settings.downcase_username

      credentials_are_valid = false
      extra_attributes = {}
      successful_authenticator = nil
      begin
        auth_index = 0
        settings.authenticators.each_with_index do |authenticator, index|
          require authenticator["source"] if authenticator["source"].present?
          auth = authenticator["class"].constantize.new

          auth.configure(HashWithIndifferentAccess.new(authenticator.merge('auth_index' => index)))

          credentials_are_valid = auth.validate(
            :username => username,
            :password => password,
            :service => service,
            :request => env
          )
          if credentials_are_valid
            extra_attributes.merge!(auth.extra_attributes) unless auth.extra_attributes.blank?
            successful_authenticator = auth
            break
          end
        end
        
        if credentials_are_valid
          tgt = generate_ticket_granting_ticket(username, extra_attributes)
          @replay[:type] = "confirmation"
          @replay[:tgt] = tgt.to_s

          if service.blank?
            @replay[:message] = t.notice.successfull_logged_in
            status 201
          else
            # TODO
            st = generate_service_ticket(service, username, tgt)

            begin
              service_with_ticket = service_uri_with_ticket(service, st)

              $LOG.info("Redirecting authenticated user '#{username}' at '#{st.client_hostname}' to service '#{service}'")
              raise NotImplementedError
              #redirect service_with_ticket, 303 # response code 303 means "See Other" (see Appendix B in CAS Protocol spec)
            rescue URI::InvalidURIError
              $LOG.error("The service '#{service}' is not a valid URI!")
              @replay[:message] = t.error.invalid_target_service
              @replay[:type] = 'error'
            end
          end
        else
          $LOG.warn("Invalid credentials given for user '#{username}'")
          @replay[:type] = 'error'
          @replay[:message] = t.error.incorrect_username_or_password
          status 401
        end
      rescue CASServer::AuthenticatorError => e
        $LOG.error(e)
        # generate another login ticket to allow for re-submitting the form
        lt = generate_login_ticket.ticket
        @replay[:lt] = lt
        @replay[:type] = 'error'
        @replay[:message] = e.to_s
        status 401
      end
      prepare_replay_for(request)
    end


    # :category: API
    # 
    # return:: Status code:
    get '/loginTicket' do
      raise NotImplementedError
    end

    # :category: API
    # 
    # return:: Status code:
    get '/validate' do
      raise NotImplementedError
    end

    # :category: API
    # 
    # return:: Status code:
    get '/validate' do
      raise NotImplementedError
    end

    # :category: API
    # 
    # return:: Status code:
    get '/serviceValidate' do
      raise NotImplementedError
    end

    # :category: API
    # 
    # return:: Status code:
    get '/proxyValidate' do
      raise NotImplementedError
    end

    # :category: API
    # 
    # return:: Status code:
    get '/proxy' do
      raise NotImplementedError
    end

    private
      def prepare_replay_for(request)
        if request.accept? 'application/json'
          return @replay.to_json
        end
        if request.accept? 'application/xml'
          # TODO 
          raise "NotImplementedError"
        end
      end
  end
end
