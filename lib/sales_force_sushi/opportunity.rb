require 'json'
module SalesForceSushi
  class Opportunity
    include SalesForceSushi::Utils
    FIELDS =  %w[id account.name amount close_date description lead_source next_step name probability stage_name type zoho_id__c]
    attr_accessor :id, :zoho_id__c, :account, :amount, :close_date, :contract, :description, :expected_revenue, :forcase_category_name,
      :last_modified_by, :lead_source, :next_step, :name, :owner, :record_type, :partner_account, :pricebook_2,
      :campain, :is_private, :probability, :total_opportunity_quality, :stage_name, :synced_quote, :type, :url,
      :api_object, :migration_complete, :attachment_names, :modified
  end
end
