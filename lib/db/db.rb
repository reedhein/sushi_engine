require 'data_mapper'
DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, "sqlite://#{Dir.pwd}/dev.db")
require_relative 'user'
require_relative 'meta'

DataMapper.finalize

DataMapper.auto_upgrade!
