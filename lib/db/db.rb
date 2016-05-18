require 'data_mapper'
DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, "sqlite://#{Dir.pwd}/dev.db")
require_relative 'user'
require_relative 'meta'
require_relative 'sales_force_progress_record'
require_relative 'zoho_progress_record'

DataMapper.finalize

DataMapper.auto_upgrade!
