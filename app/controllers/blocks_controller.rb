class BlocksController < ApplicationController

  def index
    @screen_name = session[:name]
  end

  def show
    @list = get_blocked_users
  end

  def export
    render :json => get_blocked_users.as_json
  end

  def upload
    @list = JSON.parse(params[:file].tempfile.read, :symbolize_names => true)
    render :edit
  end

  def update
    haters = params[:user].values
    block_users(haters)
    redirect_to root_url, :notice => 'blocked them haters'
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
