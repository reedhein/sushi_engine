require 'singleton'
require 'restforce'
require_relative 'base'
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

    def custom_query(query: nil, &block)
      fail ArgumentError if query.nil?
      result = @client.query(query)
      return [] if result.count < 1
      object_type = result.first.dig('attributes', 'type')
      klass = ['SalesForceSushi', object_type.camelize].join('::').classify.constantize
      result.entries.map do |entity|
        if block_given?
          yield klass.new(entity)
        else
          klass.new(entity)
        end
      end
    end

    def self.query(query_string)
      self.client.query(query_string)
    end

    def query(query_string)
      @client.query(query_string)
    end

    def self.client(user = User.first)
      Restforce.log = false
      Restforce.configure do |c|
        c.log_level = :info
      end
      Restforce.new oauth_token: user.salesforce_auth_token,
        refresh_token: user.salesforce_refresh_token,
        instance_url: CredService.creds.salesforce.instance_url,
        client_id:  CredService.creds.salesforce.api_key,
        client_secret:  CredService.creds.salesforce.api_secret,
        api_version:  CredService.creds.salesforce.api_version
    end
  end
end
