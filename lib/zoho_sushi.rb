require 'ruby_zoho'
@cnf = YAML::load(File.open('secrets.yml'))
RubyZoho.configure do |config|
  config.api_key = @cnf['zoho']['api_key']
  config.cache_fields = true
end

class ZohoSushi
  attr_accessor :saleforce, :id
  def initialize(zoho_id = nil, salesforce_client = nil)
    @salesforce = salesforce
    zoho_id.nil? ? RubyZoho::Crm::Account : RubyZoho::Crm::Account.find_by_id(zoho_id)
  end
  
  def find_pair
    @salesforce.find('Account', id, 'Zoho_ID__c')
    # @salesforce.query("select Id from Opportunity where Zoho_ID__c = '#{@zoho_id}'")
  end

  class << self

    def client
      RubyZoho::Crm
    end

    def account
      RubyZoho::Crm::Account
    end

    def task
      RubyZoho::Crm::Task
    end

    def lead
      RubyZoho::Crm::Lead
    end

    def contact
      RubyZoho::Crm::Contact
    end

    def potential
      RubyZoho::Crm::Potential
    end

    def user
      RubyZoho::Crm::User
    end

    def quote
      RubyZoho::Crm::Quote
    end
  end

end

