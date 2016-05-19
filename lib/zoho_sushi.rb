require 'ruby_zoho'
require_relative 'zoho_sushi/utils'
require_relative 'zoho_sushi/potential'
@cnf = YAML::load(File.open('secrets.yml'))
RubyZoho.configure do |config|
  config.api_key = @cnf['zoho']['api_key']
  config.cache_fields = true
end
module ZohoSushi
  class Base
    include ZohoSushi::Utils
  end
end


