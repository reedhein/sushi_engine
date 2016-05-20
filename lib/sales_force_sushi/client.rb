
module SalesForceSushi
  class Client < Restforce::Client

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

    def self.client(user = User.first)
      Restforce.new oauth_token: user.auth_token,
        refresh_token: user.refresh_token,
        instance_url: $cnf.fetch('salesforce')['instance_url'],
        client_id:  $cnf.fetch('salesforce')['api_key'],
        client_secret:  $cnf.fetch('salesforce')['api_secret'],
        api_version: "32.0"
    end
  end
end
