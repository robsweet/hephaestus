Puppet::Type.type(:satellite_channel_prefix).provide(:satellite) do
  desc "Provides Subversion support for the repo type"

  has_feature :versionable

  def create
    if this_host.current_prefix == @resource[:ensure]
      return true
    else
      satellite.channels.ensure_channel_clone_exists_for @resource[:ensure]
      this_host.channel_prefix = @resource[:ensure]
    end
  end
  alias_method :install, :create

  def destroy
    this_host.channel_prefix = ''
  end

  def exists?
      return true
  end

  def current_prefix
    this_host.current_prefix
  end

  def properties
    out = { :ensure => this_host.current_prefix }
    puts "query output = #{out.inspect}"
    out
  end

  protected

  def satellite
    @satellite ||= Satellite::Server.new
  end

  def this_host
    host = satellite.hosts(Facter.value(:fqdn))[0]
    raise "#{Facter.value(:fqdn)} (RHN id #{Facter.value(:rhn_id)}) is not registered with the Satellite server or is registered with a different name." unless host
    host
  end

end