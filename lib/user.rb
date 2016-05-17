require 'data_mapper'
DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/dev.db")

class User
  include DataMapper::Resource
  property :id, Serial
  property :user_id, String
  property :auth_token, String, length: 255
  property :refresh_token, String, length: 255

  def self.doug
    OpenStruct.new user_id: $cnf['user']['user_id'],
      auth_token: $cnf['user']['auth_token'],
      refresh_token: $cnf['user']['refresh_token']
  end
end


User.auto_migrate!

DataMapper.finalize
