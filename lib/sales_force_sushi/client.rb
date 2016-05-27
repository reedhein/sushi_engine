require 'singleton'
require 'restforce'
require_relative '../zoho_sushi'
require_relative '../../../db_share/db'
require 'pry'
module SalesForceSushi
  class Client
    attr_reader :client
    include Singleton

    def initialize(user = User.first)
      @client = self.class.client(user)
    end

    def zoho
      @zoho ||= ZohoSushi.client
    end

    def custom_query(string, &block)
      result = @client.query(string)
      result.entries.map do |entity|
        yield SalesForceSushi::Opportunity.new(entity) if block_given?
        SalesForceSushi::Opportunity.new(entity)
      end
    end

    def self.query(query_string)
      self.client.query(query_string)
    end

    def query(query_string)
      @client.query(query_string)
    end

    def self.client(user = User.first)
      Restforce.log = true
      Restforce.new oauth_token: user.auth_token,
        refresh_token: user.refresh_token,
        instance_url: $cnf.fetch('salesforce')['instance_url'],
        client_id:  $cnf.fetch('salesforce')['api_key'],
        client_secret:  $cnf.fetch('salesforce')['api_secret'],
        api_version:  $cnf.fetch('salesforce')['api_version'] || '33.0'
    end
  end
end
