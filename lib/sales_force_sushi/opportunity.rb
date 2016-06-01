require 'json'
require_relative 'base'
require_relative 'utils'
module SalesForceSushi
  class Opportunity < SalesForceSushi::Base
    include SalesForceSushi::Utils
    FIELDS =  %w[id amount description lead_source name probability stage_name type zoho_id__c created_date]
    attr_accessor :id, :zoho_id__c, :account, :amount, :close_date, :contract, :description, :expected_revenue, :forcase_category_name,
      :last_modified_by, :lead_source, :next_step, :name, :owner, :record_type, :partner_account, :pricebook_2,
      :campain, :is_private, :probability, :total_opportunity_quality, :stage_name, :synced_quote, :type, :url,
      :api_object, :migration_complete, :attachment_names, :modified, :created_date

    def contacts
      SalesForceSushi::Client.instance.custom_query(
        query: "select id, email, createddate from contact where accountid in (select accountid from opportunity where id = '#{id}')"
      )
    end

    def account
      SalesForceSushi::Client.instance.custom_query(
        query: "select id, createddate, zoho_id__c from account where id in (select accountid from opportunity where id = '#{id}')"
      ).first
    end

    def cases
      SalesForceSushi::Client.instance.custom_query(
        query: "select id, createddate, zoho_id__c from case where accountid in (select accountid from opportunity where id = '#{id}')"
      )
    end

    def notes
      SalesForceSushi::Client.instance.custom_query(
        query: "select id, createddate, body, title from note where parentid = '#{id}'"
      )
    end
  end
end
