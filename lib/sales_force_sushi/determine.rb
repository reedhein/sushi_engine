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
      corresponding_class = nil
      fun = %w[potential contact lead account].map do |zoho_object|
        puts "checking against zoho object: #{zoho_object}"
        sleep 1
        begin
          zoho_object_fields(zoho_object).map do |method_name|
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
      puts fun
      binding.pry
      return nil if corresponding_class.nil? 
      module_name = corresponding_class.first.module_name.singularize
      ["ZohoSushi" , module_name].join('::').constantize.new(corresponding_class.first)
    end

    def get_meta(object = 'opportunity')
      return_value = SalesForceSushi::Client.instance.query("select email, name, phone from contact where accountid in (select accountid from #{object} where id = '#{@sf_sushi.id}')")
      first_entry  = return_value.first
      [first_entry.fetch('Email'), first_entry.fetch('Name'), first_entry.fetch('Phone')]
    end

    private
    
    def zoho_object_fields(zoho_object)
      ZohoSushi::Base.send(zoho_object.to_sym).new.fields & [:email, :phone, :name]
    end
  end
end
