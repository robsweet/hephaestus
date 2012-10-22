require 'net/http'

class RemoteForge
  def initialize base_url = Hephaestus::Application.config.puppetlabs_forge_url
    @base_url = base_url
    url = URI.parse @base_url
    @base_host = url.host
    @base_port = url.port
  end

  def mirror_module_with_deps author, shortname
    result = Net::HTTP.get_response URI.parse("#{@base_url}/#{author}/#{shortname}.json")
    puts JSON.parse(result.body)['releases'].inspect  
    JSON.parse(result.body)['releases'].map { |the_hash| the_hash.values.first}.each do |version|
      version_result = Net::HTTP.get_response URI.parse("#{@base_url}/api/v1/releases.json?module=#{author}/#{shortname}&version=#{version}")
      JSON.parse(version_result.body).each do |full_name, versions|
        mirror_if_needed full_name, versions
      end
    end
  end

  protected

  def mirror_if_needed full_name, versions
    versions.map { |ver| ver['file'] }.each do |remote_file|
      localfile = remote_file.gsub /\/system\/releases/, Hephaestus::Application.config.local_releases_path
      if File.exist? localfile
        puts "File #{localfile} exists.  No need to mirror"
      else
        puts "File #{localfile} doesn't exist.  Downloading #{@base_url}#{remote_file}"
        FileUtils.mkdir_p File.dirname(localfile)
        Net::HTTP.start @base_host, @base_port do |http|
          resp = http.get remote_file
          File.open localfile, "wb" do |file|
            file.write resp.body
          end
        end
      end
      pm = PuppetModule.new_from_module localfile
      pm.mirrored_from_remote = true
      pm.save
    end
  end
end