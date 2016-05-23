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
  attr_accessor :processed, :meta
  def initialize( limit = 2000, offset = 0 )
    @limit           = limit
    @offset_date     = nil
    @fields          = get_opportunity_fields
    @sf_sushi        = SalesForceSushi::Client.new
    @processed = 1
    @do_work         = true
    @meta            = manage_meta
  end

  def process_work_queue(tool_class = AttachmentMigrationTool)
    begin
      while @processed > 0 do
        @processed = 0
        puts "&"*88
        puts "new batch"
        puts "&"*88

        get_sales_force_work_queue do |sf|
          if sf.migration_complete?
            puts "this sushi pair is already processed. Moving on to next"
            @processed += 1
            next
          else
            zoho = sf.find_zoho
            tool_class.new(zoho, sf, @meta).perform
          end
          @processed += 1
          puts "$"*88
          puts @processed
        end
        puts "#"*88
        puts "batch done, adding more to queue"
        puts "#"*88
      end
    rescue Net::OpenTimeout, SocketError, Errno::ETIMEDOUT
      puts "network timeout sleeping for 50 seconds"
      sleep 5
      retry
    end
    @meta.update(:end_time, DateTime.now.to_s)
    puts @processed
  end

  def get_sales_force_work_queue(&block)
    @offset_date = SalesForceProgressRecord.first(complete: false).try(:created_date).try(:to_s)
    get_unfinished_objects do |r|
      yield r if block_given?
    end
  end

  def get_unfinished_objects(&block)
    if @offset_date && !@offset_date.empty?
      query = "SELECT #{@fields} FROM Opportunity WHERE Zoho_ID__c LIKE 'zcrm%' AND CreatedDate >= #{@offset_date} ORDER BY CreatedDate LIMIT #{@limit}"
    else
      query = "SELECT #{@fields} FROM Opportunity WHERE Zoho_ID__c LIKE 'zcrm%' ORDER BY CreatedDate LIMIT #{@limit}"
    end
    @sf_sushi.custom_query(query) do |sushi|
      yield sushi if block_given?
    end
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
    meta
  end

end

binding.pry
MigrationTool.new().process_work_queue

