require 'singleton'
require 'restforce'
require_relative '../zoho_sushi'
require_relative '../../../db_share/db'
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

    def custom_query(query: , object_type: , &block)
      result = @client.query(query)

      klass = ['SalesForceSushi', object_type.camelize].join('::').classify.constantize
      result.map do |entity|
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
      Restforce.configure do |c|
        c.log_level = :info
      end
      Restforce.new oauth_token: user.auth_token,
        refresh_token: user.refresh_token,
        instance_url: $cnf.fetch('salesforce')['instance_url'],
        client_id:  $cnf.fetch('salesforce')['api_key'],
        client_secret:  $cnf.fetch('salesforce')['api_secret'],
        api_version:  $cnf.fetch('salesforce')['api_version'] || '33.0'
    end
  end
end
