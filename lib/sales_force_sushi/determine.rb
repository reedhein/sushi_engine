module SalesForceSushi
  class Determine
    attr_accessor :potential, :contact, :lead, :account
    def initialize(sf)
      @sf_sushi = sf
      @email, @name, @phone  = get_meta
      find_zoho(sf)
    end

    def find_zoho(sf)
      corresponding_class = nil
      %w[potential contact lead account].map do |zoho_object|
        puts "checking against zoho object: #{zoho_object}"
        sleep 1
        begin
          binding.pry
          self.send(zoho_object.to_sym).find_by_phone(@phone)
          self.send(zoho_object.to_sym).find_by_email(@email)
          self.send(zoho_object.to_sym).find_by_name(@name)
        rescue Net::OpenTimeout
          puts "network timeout sleeping 5 seconds then trying again"
          sleep 5
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
