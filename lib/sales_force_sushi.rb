require 'restforce'
require_relative 'sales_force_sushi/opportunity'
module SalesForceSushi
  attr_reader :user, :zoho, :zoho_id, :sales_force_id

  class Client < Restforce::Client

    def initialize(user = User.first)
      @client = self.class.client(user)
    end

    def zoho
      @zoho ||= ZohoSushi.client
    end

    def custom_query(string = nil)
      result = @client.query(string ||  "select Id, Zoho_ID__c, Account.Name, CloseDate from Opportunity limit 1")
      result.entries.delete_if do |entity|
        SalesForceProgressRecord.first(sales_force_id: entity.fetch('Id'), complete: true)
      end.map do |entity|
        SalesForceSushi::Opportunity.new(entity)
      end
    end

    def self.client(user = User.first)
      Restforce.new oauth_token: user.auth_token,
        refresh_token: user.refresh_token,
        instance_url: $cnf.fetch('salesforce')['instance_url'],
        client_id:  $cnf.fetch('salesforce')['api_key'],
        client_secret:  $cnf.fetch('salesforce')['api_secret']
    end
  end
end


