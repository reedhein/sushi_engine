require 'ruby_zoho'
@cnf = YAML::load(File.open('secrets.yml'))
RubyZoho.configure do |config|
  config.api_key = @cnf['zoho']['api_key']
  config.cache_fields = true
end

class ZohoSushi
  attr_accessor :saleforce, :api_object, :storage_object, :migration_complete, :module_name, :id

  def initialize(api_object, salesforce_client = nil)
    @api_object         = api_object
    @module_name        = api_object.module_name
    @id                 = api_object.id
    @storage_object     = conver_api_object_to_local_storage(api_object)
    @migration_complete = @storage_object.complete
    @salesforce         = salesforce_client
    self
  end

  def conver_api_object_to_local_storage(api_object)
    ZohoProgressRecord.first_or_create(
      zoho_id: api_object.id,
      module_name: api_object.module_name
    )
  end

  def migration_complete?
    migration_complete
  end

  def mark_completed
    @storage_object.update(complete: true)
    @migration_complete = true
  end

  def attachments
     self.class.client.related_records(@module_name, @id, "Attachments") || []
  end

  class << self

    def counterpart(id)
      corresponding_class = nil
      %w[potential contact lead task user quote account].detect do |zoho_object|
        puts "checking against zoho object #{zoho_object}"
        sleep 1
        begin
          corresponding_class = self.send(zoho_object.to_sym).find_by_id(zoho_id(id))
        rescue Net::OpenTimeout
          puts "network timeout sleeping 10 seconds then trying again"
          sleep 10
          retry
        end
      end
      self.new(corresponding_class.first)
    end

    def zoho_id(id)
      id.gsub('zcrm_', '')
    end

    def client
      RubyZoho.configuration.api
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

