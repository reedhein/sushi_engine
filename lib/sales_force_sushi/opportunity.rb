module SalesForceSushi
  class Opportunity
    FIELDS =  %w[id account.name amount close_date description lead_source next_step name probability stage_name type zoho_id__c]
    attr_accessor :id, :zoho_id__c, :account, :amount, :close_date, :contract, :description, :expected_revenue, :forcase_category_name,
      :last_modified_by, :lead_source, :next_step, :name, :owner, :record_type, :partner_account, :pricebook_2,
      :campain, :is_private, :probability, :total_opportunity_quality, :stage_name, :synced_quote, :type, :url
    def initialize(params)
      map_attributes(params)
      self
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

    def find_relevant
      self.class.zoho_client
    end

    def find_zoho
      corresponding_class = nil
      %w[contact potential leads].detect do |zoho_object|
        corresponding_class = ZohoSushi.send(zoho_object.to_sym).find_by_id(zoho_id(zoho_id__c))
      end
      corresponding_class.first
    end

    def zoho_id(id)
      puts id.gsub('zcrm_', '')
      id.gsub('zcrm_', '')
    end
  end
end
