require File.dirname(__FILE__)+"/../satellite"

Puppet::Type.newtype(:satellite_channel_prefix) do
  @doc = "Puppet will access our Satellite instance and ensure that a set of channels exists for the
          given prefix and that this host is subscribed to them."

  feature :versionable, "The provider can set get the prefix for Satellite channels."

  ensurable do
    desc "The prefix of the channel label that this machine should be subscribed to.  The current base channel label is rhel-x86_64-server-6."

    newvalue(/.*/) do
      resource[:provider] = :satellite
      begin
        provider.install
      rescue => detail
        self.fail "Could not set channel prefix: #{detail}"
      end
    end

    def retrieve
      provider.current_prefix
    end
  end

  newparam(:name) do
    desc "An arbitrary tag for your own reference; the name of the message."
    isnamevar
  end
end
