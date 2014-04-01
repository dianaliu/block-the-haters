require 'sinatra'
require 'sinatra/config_file'
require 'omniauth-twitter'
require 'twitter'
require 'json'


class App < Sinatra::Base
  configure do
    enable :sessions
    register Sinatra::ConfigFile
    config_file 'config.yml'

    use OmniAuth::Builder do
      provider :twitter, ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET']
    end
  end

  configure :development, :testing do
    set :session_secret, "~session-secret~"
    ENV['TWITTER_CONSUMER_KEY'] = settings.TWITTER_CONSUMER_KEY
    ENV['TWITTER_CONSUMER_SECRET'] = settings.TWITTER_CONSUMER_SECRET
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

  get 'auth/failure' do
    "authentication failed"
  end

  get '/' do
    erb :index, locals: { :twitter_name => session[:name]}
  end

  get '/blocks' do
    erb :blocks, locals: { :block_list => get_blocked_users }
  end

  get '/export.json' do
    content_type :json
    get_blocked_users.to_json
  end

  post '/upload' do
    # TODO: Check for invalid files and formats
    block_list = JSON.parse(params[:file][:tempfile].read, :symbolize_names => true)
    erb :block_form, locals: { :block_list => block_list }
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
end
