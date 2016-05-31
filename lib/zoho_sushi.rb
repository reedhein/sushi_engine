require 'ruby_zoho'
require 'pry'
require_relative 'zoho_sushi/utils'
require_relative 'zoho_sushi/potential'

RubyZoho.configure do |config|
  config.api_key = CredService.creds.zoho.api_key
  config.cache_fields = true
end
module ZohoSushi
  class Base
    include ZohoSushi::Utils
  end
end


