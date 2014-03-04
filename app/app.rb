require 'sinatra/base'
require 'sinatra/assetpack'
require 'omniauth-twitter'
require 'twitter'
require 'json'

class BlockTheHaters < Sinatra::Base
  set :root, File.dirname(__FILE__)
  register Sinatra::AssetPack

  assets do

    serve '/css', :from => 'css'
    css :foundation, [
      '/css/normalize.css',
      '/css/foundation.min.css'
    ]

    prebuild true
  end

  configure do
    enable :sessions

    use OmniAuth::Builder do
      provider :twitter, ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET']
    end
  end

  helpers do
    # define a current_user method, so we can be sure if an user is authenticated
    def current_user
      !session[:uid].nil?
    end
  end

  get '/auth/twitter/callback' do
    # probably you will need to create a user in the database too...
    session[:uid] = env['omniauth.auth']['uid']
    session[:name] = env['omniauth.auth']['info']['nickname']
    session[:access_token] = env['omniauth.auth']['credentials']['token']
    session[:access_token_secret] = env['omniauth.auth']['credentials']['secret']

    # this is the main endpoint to your application
    redirect to('/')
  end

  get '/auth/failure' do
    # omniauth redirects to /auth/failure when it encounters a problem
    # so you can implement this as you please
    "twitter omni-auth failed."
  end

  get '/' do
    erb :index, :layout => :app_layout, locals: { :twitter_name => session[:name]}
  end

  get '/blocks' do
    erb :blocks, :layout => :app_layout, locals: { :block_list => get_blocked_users }
  end

  get '/export.json' do
    content_type :json
    get_blocked_users.to_json
  end

  post '/upload' do
    # TODO: Check for invalid files and formats
    block_list = JSON.parse(params[:file][:tempfile].read, :symbolize_names => true)
    erb :block_form, :layout => :app_layout, locals: { :block_list => block_list }
  end

  post '/block_users' do
    # Only receive those checked users screen_names or user_ids
    users = params.values
    block_users(users)

    'okay, blocked'
  end

  private

  def get_blocked_users
    client = Twitter::REST::Client.new({
      :consumer_key => ENV['TWITTER_CONSUMER_KEY'],
      :consumer_secret => ENV['TWITTER_CONSUMER_SECRET'],
      :access_token => session[:access_token],
      :access_token_secret => session[:access_token_secret]
      })

    # Returns a cursor, is this all of them?
    blocked_users = client.blocking.to_a
    formatted_blocked_users = [].tap do |list|
      blocked_users.each { |u|  list << { :screen_name => u.screen_name, :user_id => u.id } }
    end
  end

  def block_users(users=[])
    client = Twitter::REST::Client.new({
      :consumer_key => ENV['TWITTER_CONSUMER_KEY'],
      :consumer_secret => ENV['TWITTER_CONSUMER_SECRET'],
      :access_token => session[:access_token],
      :access_token_secret => session[:access_token_secret]
      })

    # Can receive a mixed array of screen_names and user_ids
    client.block users
  end

  def get_your_following
    # TODO: Don't block anybody you're following
  end

  run! if app_file == $0
end
