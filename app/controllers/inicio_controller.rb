class InicioController < ApplicationController
  def index
    @news = Hash.new
    ws = GithubService.new

    ws.dame_issues.each  do |x|
     @news.merge!({x['title'] => x['body'].html_safe})
    end
  end

  def acerca
  end

  def error
  end
end
