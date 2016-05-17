require 'restforce'
require_relative 'sales_force_sushi/opportunity'
module SalesForceSushi
  attr_reader :user, :zoho, :zoho_id, :sales_force_id

  class Client < Restforce::Client
    def zoho
      @zoho ||= ZohoSushi.client
    end

    def initialize(user = User.doug)
      @client = self.class.client(user)
    end

    def query(string = nil)
      result = @client.query(string ||  "select Id, Zoho_ID__c, Account.Name, CloseDate from Opportunity limit 1")
      result.entries.map do |entity|
        SalesForceSushi::Opportunity.new(entity)
      end
    end

    def self.client(user = User.doug)
      Restforce.new oauth_token: user.auth_token,
        refresh_token: user.refresh_token,
        instance_url: $cnf['sales_force']['instance_url'],
        client_id:  $cnf['sales_force']['api_key'],
        client_secret:  $cnf['sales_force']['api_secret']
    end
  end
end


