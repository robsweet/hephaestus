require 'net/http'

class PuppetModuleController < ApplicationController

  respond_to :json
  before_filter :find_local_module, :proxy_if_not_local

  PUPPETLABS_FORGE_URL = "http://forge.puppetlabs.com"

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
    proxy unless @module
  end


  def show
    Rails.logger.debug @module.as_releases_hash.as_json
    respond_with @module.as_releases_hash
  end

  def releases
    Rails.logger.debug @module.as_json
    respond_with @module
  end

  def proxy
    uri = URI.parse("#{PUPPETLABS_FORGE_URL}#{request.fullpath}")
    Rails.logger.debug "Trying to proxy #{uri}"
    result = Net::HTTP.get_response uri
    Rails.logger.debug result.body
    render :text => result.body
  end
end
