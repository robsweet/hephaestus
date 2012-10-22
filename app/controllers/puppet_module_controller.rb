require 'net/http'

class PuppetModuleController < ApplicationController

  respond_to :json
  before_filter :find_local_module, :proxy_if_not_local

  def releases
    Rails.logger.debug @module.releases_hash.as_json
    respond_with @module.as_releases_hash
  end

  def dependencies
    Rails.logger.debug @module.as_json
    respond_with @module
  end

end
