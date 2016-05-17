require 'rubygems'
require 'omniauth-salesforce'
require 'pry'
require 'pry-byebug'
require 'active_support/all'
require_relative 'lib/user'
require_relative 'lib/zoho_sushi'
require_relative 'lib/sales_force_sushi'

$cnf = YAML::load(File.open('secrets.yml'))
user = User.first
criteria = SalesForceSushi::Opportunity::FIELDS.map do |x|
  if x =~ /__/
    x
  else
    x.camelize
  end
end.join(', ')
c = SalesForceSushi::Client.new
# b = c.query( "SELECT #{criteria}
#               FROM Opportunity
#               WHERE Zoho_ID__c
#               LIKE 'zcrm%'
#               LIMIT 1"
#            )
contact_with_attachments = "1041863000006597931"
b = c.query( "SELECT #{criteria}
              FROM Opportunity
              WHERE Zoho_ID__c
              LIKE 'zcrm%'
              LIMIT 1"
           )
def funtimes(contact_with_attachments)
  RubyZoho.configuration.api.related_records("Contacts", contact_with_attachments, "Attachments")
end
derp = funtimes(contact_with_attachments)
lol = b.first
puts user


