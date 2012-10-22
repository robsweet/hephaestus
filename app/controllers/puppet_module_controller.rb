require 'net/http'

class PuppetModuleController < ApplicationController

  respond_to :json
  before_filter :find_or_mirror_module

  def releases
    # Rails.logger.debug @module.releases_hash.as_json
    respond_with @module.releases_hash
  end

  def dependencies
    # Rails.logger.debug @module.dependencies_hash.as_json
    respond_with @module.dependencies_hash
  end

  protected

  def find_or_mirror_module
    (author,shortname) =  params['user'] ? [params['user'], params['module']] : params['module'].split("/")
    @module = PuppetModule.find_or_mirror author, shortname, params['version']
  end

end
