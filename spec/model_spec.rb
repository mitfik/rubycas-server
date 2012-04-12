# encoding: UTF-8
require File.dirname(__FILE__) + '/spec_helper'
require 'casserver/model'
require 'casserver/server'

describe CASServer::Model::LoginTicket, '.cleanup(max_lifetime, max_unconsumed_lifetime)' do
  let(:max_lifetime) { -1 }
  let(:max_unconsumed_lifetime) { -2 }

  def app
    CASServer::Server
  end

  before do
    load_server(app)
    reset_spec_database(app)
    
    CASServer::Model::LoginTicket.create :ticket => 'test', :client_hostname => 'test.local'
  end

  it 'should destroy all tickets created before the max lifetime' do
    expect {
      CASServer::Model::LoginTicket.cleanup(max_lifetime, max_unconsumed_lifetime)
    }.to change(CASServer::Model::LoginTicket, :count).by(-1)
  end

  it 'should destroy all unconsumed tickets not exceeding the max lifetime' do
    expect {
      CASServer::Model::LoginTicket.cleanup(max_lifetime, max_unconsumed_lifetime)
    }.to change(CASServer::Model::LoginTicket, :count).by(-1)
  end
end

describe CASServer::Model::LoginTicket, '#to_s' do
  let(:ticket) { 'test' }

  before do
    @login_ticket = CASServer::Model::LoginTicket.new :ticket => ticket
  end

  it 'should delegate #to_s to #ticket' do
    @login_ticket.to_s.should == ticket
  end
end
