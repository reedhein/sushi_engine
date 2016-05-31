require 'restforce'
path = File.dirname(File.absolute_path(__FILE__) )
Dir.glob(path + '/**/*'){|file| require file}
