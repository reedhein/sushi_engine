module SalesForceSushi
  module Utils
    def initialize(api_object)
      @api_object         = api_object
      @storage_object     = conver_api_object_to_local_storage(api_object)
      map_attributes(api_object)
      self
    end

    def conver_api_object_to_local_storage(api_object)
      SalesForceProgressRecord.first_or_create(
        sales_force_id: api_object.fetch('Id'),
        object_type: api_object.fetch('attributes').fetch('type'),
        created_date: DateTime.parse(api_object.fetch('CreatedDate'))
      )
    end

    def migration_complete?
      @migration_complete ||= @storage_object.complete
    end

    def mark_completed
      @storage_object.update(complete: true)
      @migration_complete = true
    end

    def modified?
      @modified
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
      # description = description_from_file_data(file_data)
      begin
        file = ZohoSushi::Base.client.download_file(zoho_sushi.module_name, file_data[:id])
        SalesForceSushi::Client.instance.client.create('Attachment',
                                                        Body: Base64::encode64(file),
                                                        Description: "imported from zoho ID: #{zoho_sushi.id}",
                                                        Name: file_data[:file_name],
                                                        ParentId: id)
        @modified = true
      rescue Errno::ETIMEDOUT
        puts 'api timeout waiting 10 seconds and retrying'
        sleep 10
        retry
      rescue => e
        puts e
        binding.pry
      end
    end

    def find_relevant
      self.class.zoho_client
    end

    def find_zoho
      zoho = ZohoSushi::Base.counterpart(zoho_id__c) || SalesForceSushi::Determine.new(self)
      @storage_object.update(zoho_object_type: zoho.module_name)
      zoho
    end

    def attachments
      @attachments ||= SalesForceSushi::Client.instance.query("SELECT Id, Name FROM Attachment WHERE ParentId = '#{id}'")
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
