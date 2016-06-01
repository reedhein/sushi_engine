require 'pathname'
require_relative 'base'
require_relative 'utils'
module SalesForceSushi
  class Attachment < SalesForceSushi::Base
    include SalesForceSushi::Utils
    attr_accessor :parent_id, :name, :created_date, :id, :type, :url, :body,
      :problems, :local_presence, :migration_complete, :storage_object

    def save_locally(backup_path, id_mapping)
      parent_class    = get_parent_class(id_mapping)
      file_directory  = create_file_directory(backup_path, parent_class)
      file            = file_pointer(file_directory)
      @local_presence = file.exist?
      begin
        if @local_presence == false && @api_object['Body']
          write_file(file)
        elsif @local_presence == false && @api_object['Body'] == nil
          #this is a kludge b/c I need to get all these ids first.  it's a long story about how moving the createddate market in query returns same results
          @api_object = SalesForceSushi::Client.query("select parentid, name, id, createddate, body from attachment WHERE id = '#{@id}'").first
          binding.pry unless @api_object
          save_locally(backup_path, id_mapping)
        elsif @local_presence == true && file.size == 0 && @api_object['Body'] && @api_object.Body.size > 0
          write_file(file)
          @problems << "file size zero"
        end
      rescue Faraday::ConnectionFailed
        puts 'connection failed, retrying'
        sleep 5
        retry
      rescue => e
        puts "*"*88
        puts e
        binding.pry
        false
      ensure
        @storage_object.attachment_complete = false
        @storage_object.save
      end
    end

    def write_file(file)
      File.open(file, 'w') do |f| 
        f.write(@api_object.Body)
      end
    end

    def file_pointer(file_dir)
      file_location = [file_dir, @name.gsub('/', '\\')].join('/') #forward slashes in file names fucks with Pathname library
      Pathname.new(file_location)
    end

    def create_file_directory(backup_path, parent_class)
      file_dir = [backup_path, parent_class, parent_id].join('/')
      Pathname.new(file_dir).mkpath
      Pathname.new(file_dir).to_s
    end

    def mark_completed
      @storage_object.attachment_complete = true
      @migration_complete = @storage_object.save
    end

    def migration_complete?
      @migration_complete ||= @storage_object.attachment_complete
    end

    def get_parent_class(id_mapping)
      key = parent_id.slice(0..2)
      id_mapping.fetch(key, "generic").downcase.camelize
    end
  end
end
