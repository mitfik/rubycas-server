# encoding: UTF-8
require File.dirname(__FILE__) + '/spec_helper'
require 'lib/casserver/api'

$LOG = Logger.new(File.basename(__FILE__).gsub('.rb','.log'))

module LoggedInAsUser
  extend RSpec::Core::SharedContext
  before(:each) do
    post '/login', { :username => "spec_user", :password => "spec_password"}, "HTTP_ACCEPT" => "application/json"
    last_response.status == 201
    @body = JSON.parse(last_response.body)
  end
end

describe 'Api' do

  def app
    CASServer::APIServer
  end

  before do
    load_server(app)
    reset_spec_database(app)
  end

  describe 'json' do
    include Rack::Test::Methods

    it 'check if cas is alive' do
      get '/isalive', {}, "HTTP_ACCEPT" => "application/json"
      last_response.body.should == ""
      last_response.status == 204
    end

    it 'get 404 when use text/html as a http_accept' do
      get '/isalive', {}, "HTTP_ACCEPT" => "text/html"
      last_response.status == 404
      get '/isalive'
      last_response.status == 404
    end

    it 'get 404 when use diffrent http_accept then json or xml' do
      post '/login', { :username => "test", :password => "1233456"}
      last_response.status == 404
    end

    describe 'user is logged' do
      include LoggedInAsUser

      it 'should get tgt' do
        @body["type"].should eq "confirmation"
        @body["tgt"].length.should be > 1
        @body["tgt"].should =~ /TGC\-+\w/
      end
  
      describe "logout user" do
        it 'should logout' do
          set_cookie "tgt=#{@body['tgt']}"
          delete "/logout", {}, "HTTP_ACCEPT" => "application/json"
          body = JSON.parse(last_response.body)
          body["type"].should eq "confirmation"
          last_response.status.should == 200
        end

        it 'should inform that tgt is incorrect and return 203' do
          set_cookie "tgt=1234124124124124"
          delete "/logout", {}, "HTTP_ACCEPT" => "application/json"
          body = JSON.parse(last_response.body)
          body["type"].should eq "notice"
          last_response.status.should == 203
        end
      end
    end
  end


end
