require 'net/http'

class RemoteForge
  def self.refresh_mirrored_modules
    modules_to_mirror = PuppetModule.where("mirrored_from is not null").group("name")
    forge = self.new

    modules_to_mirror.each do |puppet_module|
      forge.mirror_module_with_deps puppet_module.author, puppet_module.shortname
    end
  end

  attr_accessor :repair_mode

  def initialize base_url = Hephaestus::Application.config.puppetlabs_forge_url
    @base_url = base_url
    url = URI.parse @base_url
    @base_host = url.host
    @base_port = url.port
    @repair_mode = false
  end

  def mirror_module_with_deps author, shortname
    result = Net::HTTP.get_response URI.parse("#{@base_url}/#{author}/#{shortname}.json")
    response = JSON.parse(result.body)
    if response['error']
      Rails.logger. "Error trying to mirror #{author}/#{shortname}"
    else
      response['releases'].map { |the_hash| the_hash.values.first}.each do |version|
        version_result = Net::HTTP.get_response URI.parse("#{@base_url}/api/v1/releases.json?module=#{author}/#{shortname}&version=#{version}")
        JSON.parse(version_result.body).each do |full_name, versions|
          mirror_if_needed full_name, versions
        end
      end
    end
  end

  protected

  def mirror_if_needed full_name, versions
    versions.map { |ver| ver['file'] }.each do |remote_file|
      localfile = remote_file.gsub /\/system\/releases/, Hephaestus::Application.config.local_releases_path
      if File.exist? localfile
        Rails.logger.debug "File #{localfile} exists.  No need to mirror"
      else
        Rails.logger.debug "File #{localfile} doesn't exist.  Downloading #{@base_url}#{remote_file}"
        FileUtils.mkdir_p File.dirname(localfile)
        Net::HTTP.start @base_host, @base_port do |http|
          resp = http.get remote_file
          File.open localfile, "wb" do |file|
            file.write resp.body
          end
        end
      end

      create_module_from_tarball localfile if @repair_mode || !File.exist?(localfile)
    end
  end

  def create_module_from_tarball tarball
    pm = PuppetModule.new_from_module_tarball tarball
    pm.mirrored_from = @base_url
    pm.mirrored_on = Time.now
    pm.save
  end
end