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

class MigrationTool
  attr_accessor :work_queue, :meta
  def initialize( limit = 2000, offset = 0 )
    @limit          = limit
    @offset_date = nil
    @fields     = get_opportunity_fields
    @sf_sushi   = SalesForceSushi::Client.new
    @meta       = manage_meta
    @work_queue = get_sales_force_work_queue
  end

  def process_work_queue(tool_class = AttachmentMigrationTool)
    begin
      while !@work_queue.empty? do 
        @work_queue.each do |sf|
          if sf.migration_complete? == true
            puts "this sushi pair is already processed. Moving on to next"
            next
          end
          zoho = sf.find_zoho
          tool_class.new(zoho, sf, @meta).perform
        end
        @offset_date = @work_queue.last.created_date
        puts "adding more to queue"
        @work_queue = get_sales_force_work_queue
      end
    rescue Net::OpenTimeout, SocketError, Errno::ETIMEDOUT
      puts "network timeout sleeping for 10 seconds"
      sleep 10
      retry
    end
    @meta.udpate(:end_time, DateTime.now)
  end

  def get_sales_force_work_queue
    result = get_unfinished_objects
    while result.empty? do
      @offset_date = SalesForceProgressRecord.last.created_date.to_s
      result = get_unfinished_objects
    end
    result
  end

  def get_unfinished_objects
    if @offset_date && !@offset_date.empty?
      query = "SELECT #{@fields} FROM Opportunity WHERE Zoho_ID__c LIKE 'zcrm%' AND CreatedDate >= #{@offset_date} ORDER BY CreatedDate LIMIT #{@limit}"
    else
      query = "SELECT #{@fields} FROM Opportunity WHERE Zoho_ID__c LIKE 'zcrm%' ORDER BY CreatedDate LIMIT #{@limit}"
    end
    @sf_sushi.custom_query(query)
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

  def manage_meta
    meta = Meta.first_or_create
    if meta.persistence_state?
      meta.restart_count += 1
    else
      meta.update(start_time: DateTime.now)
    end
  end

end

binding.pry
MigrationTool.new().process_work_queue

