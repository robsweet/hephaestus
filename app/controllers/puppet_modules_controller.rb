require 'net/http'

class PuppetModulesController < ApplicationController

  respond_to :json
  before_filter :find_or_mirror_module, :except => [:index, :new, :create]

  def index
    respond_to do |format|
      format.html { render }
      format.json { render :json => PuppetModule.all.map { |mod| mod.full_name } }
    end
  end

  def new
  end

  def create
    @module = PuppetModule.new_from_module_tarball params['puppet_module']['tarball'].tempfile.path
    if @module.save
      FileUtils.mkdir_p File.dirname(@module.filename)
      FileUtils.move params['puppet_module']['tarball'].tempfile.path, @module.filename
    end

    respond_to do |format|
      format.html do
        if @module.valid?
          flash['info'] = "Module #{@module.filename} saved."
        else
          flash[:error] = @module.errors.full_messages
          Rails.logger.error @module.errors.full_messages
        end
        redirect_to new_puppet_modules_path
      end

      format.json do
        if @module.valid?
          render :json => @module, :status => 201
        else
          render :json => @module.errors.full_messages, :status => 422
        end
      end
    end
  end

  def destroy
    if params['version']
      @module.destroy
      respond_with 'OK', :status => 200
    else
      respond_with @module.releases_hash, :status => 300
    end
  end

  def show
    respond_with @module
  end

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
