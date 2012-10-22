class ApplicationController < ActionController::Base
  protect_from_forgery
  
  def find_local_module
    if    params['user'] && params['module']
      @module = PuppetModule.by_author_and_shortname(params['user'], params['module']).first
    elsif params['module'] && params['version']
      (user,shortname) = params['module'].split /[\/-]/, 2
      @module = PuppetModule.by_author_and_shortname(user, shortname).where(:version => params['version']).first
    end
    Rails.logger.error "Can't find module for #{params.inspect} locally.  Time to proxy!" unless @module
  end

  def proxy_if_not_local
    unless @module
      uri = URI.parse("#{PUPPETLABS_FORGE_URL}#{request.fullpath}")
      Rails.logger.debug "Trying to proxy #{uri}"
      result = Net::HTTP.get_response uri
      Rails.logger.debug result.body
      render :text => result.body
    end
  end

end
