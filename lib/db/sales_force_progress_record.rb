class SalesForceProgressRecord
  include DataMapper::Resource
  property :id, Serial
  property :sales_force_id, String, length: 255
  property :object_type, String, length: 255
  property :complete, Boolean, default: false
end
