require 'json'
module SalesForceSushi
  class Opportunity
    FIELDS =  %w[id account.name amount close_date description lead_source next_step name probability stage_name type zoho_id__c]
    attr_accessor :id, :zoho_id__c, :account, :amount, :close_date, :contract, :description, :expected_revenue, :forcase_category_name,
      :last_modified_by, :lead_source, :next_step, :name, :owner, :record_type, :partner_account, :pricebook_2,
      :campain, :is_private, :probability, :total_opportunity_quality, :stage_name, :synced_quote, :type, :url,
      :api_object, :migration_complete, :attachment_names
    def initialize(api_object)
      @api_object       = api_object
      @storage_object   = conver_api_object_to_local_storage(api_object)
      @migration_complete = @storage_object.complete
      map_attributes(api_object)
      self
    end

    def conver_api_object_to_local_storage(api_object)
      SalesForceProgressRecord.first_or_create(
        sales_force_id: api_object.fetch('Id'),
        object_type: api_object.fetch('attributes').fetch('type')
      )
    end

    def migration_complete?
      migration_complete
    end

    def mark_completed
      @storage_object.update(complete: true)
      @migration_complete = true
    end

    def map_attributes(params)
      params.each do |key, value|
        next if key == "attributes"
        self.send("#{key.underscore}=", value)
      end
      params.fetch('attributes').each do |key, value|
        self.send("#{key.underscore}=", value)
      end
    end

    def attach(zoho_sushi, file_data)
      if file_already_present?(file_data)
        puts "*" * 88
        puts "WARNING this file was discoverd in SFDC id: #{id}"
        puts "*" * 88
        return
      end
      description = description_from_file_data(file_data)
      file = ZohoSushi.client.download_file(zoho_sushi.module_name, file_data[:id])
      begin
        binding.pry
        SalesForceSushi::Client.new.create('Attachment',
                                              Body: file,
                                              Description: description,
                                              Name: file_data[:file_name],
                                              ParentId: id
                                            )
      rescue => e
        puts e
        binding.pry
      end
    end

    def find_relevant
      self.class.zoho_client
    end

    def find_zoho
      ZohoSushi.counterpart(zoho_id__c)
    end

    def attachments
      @attachments ||= SalesForceSushi::Client.client.query("SELECT Id, Name FROM Attachment WHERE ParentId = '#{id}'")
    end

    private

    def file_already_present?(file_data)
      puts 'testing for presence'
      attachments.entries.map{|attachment| attachment.fetch('Name')}.include? file_data[:file_name]
    end

    def description_from_file_data(file_data)
      [
       "Zoho migrated file", 
       "Attached by: #{file_data[:attached_by]}",
       "Last modified: #{file_data[:modified_time]}"
      ]
    end
  end
end
