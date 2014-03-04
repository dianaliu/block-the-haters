module ApplicationHelper

  def current_user
    session[:uid]
  end
end
