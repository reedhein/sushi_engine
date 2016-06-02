module SalesForceSushi
  class Determine
    attr_accessor :potentials, :contacts, :leads, :accounts, :email, :name, :phone
    def initialize(sf)
      @sf_sushi = sf
      @potentials, @contacts, @leads, @accounts = [], [], [], []
      @email, @name, @phone  = get_meta
      find_zoho(sf)
    end

    def find_zoho(sf)
      corresponding_objects = fetch_zoho_objects(sf)
      return_value = corresponding_objects.flatten.compact.map do |zoho|
        begin
          module_name = zoho.module_name.singularize
          ["ZohoSushi" , module_name].join('::').constantize.new(zoho)
        rescue => e
          puts e
          binding.pry
        end
      end.compact
      puts return_value
    end

    def fetch_zoho_objects(sf)
      %w[potential contact lead account].map do |zoho_object|
        puts "checking against zoho object: #{zoho_object}"
        begin
          zoho_object_fields(zoho_object).compact.map do |method_name|
            zoho_api_lookup = ZohoSushi::Base.send(zoho_object.to_sym).send("find_by_#{method_name.to_s}", self.send(method_name))
            if zoho_api_lookup
              zoho_api_lookup.each do |zoho|
                self.send(zoho_object.pluralize) << zoho
              end
            end
          end
        rescue Net::OpenTimeout
          puts "network timeout sleeping 5 seconds then trying again"
          sleep 5
          retry
        end
      end
    end


    def get_meta
      case @sf_sushi.type 
      when 'Contact'
        return_value = SalesForceSushi::Client.instance.query("SELECT email, name, phone FROM contact WHERE id = '#{@sf_sushi.id}'")
      when 'Opportunity'
        return_value = SalesForceSushi::Client.instance.query("SELECT email, name, phone FROM contact WHERE accountid IN (SELECT accountid FROM Opportunity WHERE id = '#{@sf_sushi.id}')")
      when 'Account'
        return_value = SalesForceSushi::Client.instance.query("SELECT email, name, phone FROM contact WHERE accountid = '#{@sf_sushi.id}'")
      end
      first_entry  = return_value.first || {}
      [first_entry.fetch('Email', nil), first_entry.fetch('Name', nil), first_entry.fetch('Phone', nil)]
    end

    private
    
    def zoho_object_fields(zoho_object)
      ZohoSushi::Base.send(zoho_object.to_sym).new.fields & [:email, :phone, :name]
    end
  end
end
