class Meta
  include DataMapper::Resource
  property :id, Serial
  property :start_time, DateTime
  property :end_time, DateTime
  property :current_offset, Integer
end
