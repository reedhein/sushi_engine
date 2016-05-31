require 'rubygems'
require 'asciiart'
require 'sinatra'
require 'haml'
require 'omniauth-salesforce'
require 'pry'
require_relative '../db_share/db'
require_relative 'lib/zoho_sushi'
require_relative 'lib/sales_force_sushi'

a = AsciiArt.new([Dir.pwd, 'assets', 'sushi.jpg'].join('/'))
puts a.to_ascii_art(color: true, width: 95)
$cnf = YAML::load(File.open('secrets.yml'))
class SalesForceApp < Sinatra::Base
  set env: :development
  set port: 9494
  set :bind, '0.0.0.0'
  use Rack::Session::Pool
  use OmniAuth::Builder do
    provider :salesforce, $cnf['salesforce']['api_key'], $cnf['salesforce']['api_secret']
  end

  post '/authenticate' do
    auth_params = {
      :display => 'page',
      :immediate => 'false',
      :scope => 'full refresh_token'
    }
    auth_params = URI.escape(auth_params.collect{|k,v| "#{k}=#{v}"}.join('&'))
    redirect "/auth/salesforce?#{auth_params}"
  end

  get '/' do
    haml :index
  end

  get '/unauthenticate' do
    # request.env['rack.session'] = {}
    session.clear
    redirect '/'
  end

  get '/auth/failure' do
    haml :error, :locals => { :message => params[:message] } 
  end

  get '/auth/:provider/callback' do
    user = User.first_or_create(user_id: env['omniauth.auth']['extra']['user_id'])
    user.auth_token     = env['omniauth.auth']['credentials']['token']
    user.refresh_token  = env['omniauth.auth']['credentials']['refresh_token']
    user.save
    session[:auth_hash] = env['omniauth.auth']
    redirect '/' unless session[:auth_hash] == nil
  end

  get '/error' do
  end

  get '/*' do
    haml :index 
  end

  error do
    haml :error
  end

  helpers do
    def sanitize_provider(provider = nil)
      provider.strip!    unless provider == nil
      provider.downcase! unless provider == nil
      provider = "salesforce" unless %w(salesforcesandbox salesforceprerelease databasedotcom).include? provider
      provider
    end

    def htmlize_hash(title, hash)
      hashes = nil
      strings = nil
      hash.each_pair do |key, value|
        case value
        when Hash
          hashes ||= ""
          hashes << htmlize_hash(key,value)
        else
          strings ||= "<table>"
          strings << "<tr><th scope='row'>#{key}</th><td>#{value}</td></tr>"
        end
      end
      output = "<div data-role='collapsible' data-theme='b' data-content-theme='b'><h3>#{title}</h3>"
      output << strings unless strings.nil?
      output << "</table>" unless strings.nil?
      output << hashes unless hashes.nil?
      output << "</div>"
      output
    end
  end
  
  private

  `say sushi is coming online` if RbConfig::CONFIG['host_os'] =~ /darwin/
  run! if app_file == $0
end

