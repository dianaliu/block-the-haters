class SessionsController < ApplicationController
  def create
    session[:uid] = env['omniauth.auth']['uid']
    session[:name] = env['omniauth.auth']['info']['nickname']
    session[:access_token] = env['omniauth.auth']['credentials']['token']
    session[:access_token_secret] = env['omniauth.auth']['credentials']['secret']

    redirect_to root_url
  end

  def destroy
  end
end
