class ZohoProgressRecord
  include DataMapper::Resource
  property :id, Serial
  property :zoho_id, String, length: 255
  property :module_name, String, length: 255
  property :complete, Boolean, default: false
end
