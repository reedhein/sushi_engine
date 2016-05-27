module SalesForceSushi
  class Determine
    def initialize(sf)
      @sf_sushi = sf
      @email, @name, @phone  = get_meta
      find_zoho(sf)
    end
    def find_zoho(sf)
      corresponding_class = nil
      %w[potential contact lead account].detect do |zoho_object|
        puts "checking against zoho object: #{zoho_object}"
        sleep 1
        begin
          binding.pry
          corresponding_class = self.send(zoho_object.to_sym).find_by_id(sf.zoho_id__c)
          corresponding_class = self.send(zoho_object.to_sym).find_by_email(zoho_id(id))
          corresponding_class = self.send(zoho_object.to_sym).find_by_name(zoho_id(id))
        rescue Net::OpenTimeout
          puts "network timeout sleeping 10 seconds then trying again"
          sleep 10
          retry
        end
      end
      return nil if corresponding_class.nil? 
      module_name = corresponding_class.first.module_name.singularize
      ["ZohoSushi" , module_name].join('::').constantize.new(corresponding_class.first)
    end

    def get_meta(object = 'opportunity')
      return_value = SalesForceSushi::Client.instance.query("select email, name, phone from contact where accountid in (select accountid from #{object} where id = '#{sf.id}')")
      first_entry  = return_value.entites.first
      [first_entry.fetch('Email'), first_entry.fetch('Name'), first_entry.fetch('Phone')]
    end
  end
end
