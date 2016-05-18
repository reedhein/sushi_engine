require 'rubygems'
require 'omniauth-salesforce'
require 'pry'
require 'pry-byebug'
require 'active_support/all'
require_relative 'lib/db/db'
require_relative 'lib/zoho_sushi'
require_relative 'lib/sales_force_sushi'
require_relative 'lib/attachment_migration_tool'

$cnf = YAML::load(File.open('secrets.yml'))
# contact_with_attachments = "1041863000006597931"
# binding.pry
# def funtimes(contact_with_attachments)
#   RubyZoho.configuration.api.related_records("Contacts", contact_with_attachments, "Attachments")
# end
# derp = funtimes(contact_with_attachments)
# test = RubyZoho.configuration.api.download_file('Contacts', derp.first[:id])

class MigrationTool
  attr_accessor :work_queue
  def initialize( limit = 200, offset = 0 )
    @limit      = limit
    @offset     = offset
    @fields     = get_opportunity_fields
    @sf_sushi   = SalesForceSushi::Client.new
    @work_queue = get_sales_force_work_queue
  end

  def process_work_queue
    begin
      while !@work_queue.empty? do 
        @work_queue.each do |sf|
          if sf.migration_complete? == true
            puts "this sushi pair is already processed. Moving on to next"
            next
          end
          zoho = sf.find_zoho
          AttachmentMigrationTool.new(zoho, sf).transfer
        end
        @offset += 200
        puts "adding more to queue"
        @work_queue = get_sales_force_work_queue
      end
    rescue Net::OpenTimeout, SocketError
      puts "network timeout sleeping for 30 seconds"
      sleep 30
      retry
    end
  end

  def get_sales_force_work_queue
    result = get_unfinished_objects
    while result.empty? do
      @offset += 200
      result = get_unfinished_objects
    end
    result
  end

  def get_unfinished_objects
    @sf_sushi.custom_query(
      "SELECT #{@fields} FROM Opportunity WHERE Zoho_ID__c LIKE 'zcrm%' LIMIT #{@limit} OFFSET #{@offset} "
    )
  end

  def get_opportunity_fields
    SalesForceSushi::Opportunity::FIELDS.map do |x|
      if x =~ /__/
        x
      else
        x.camelize
      end
    end.join(', ')
  end

end

MigrationTool.new().process_work_queue

