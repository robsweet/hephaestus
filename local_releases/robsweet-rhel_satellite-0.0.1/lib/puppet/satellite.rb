require 'yaml'
require 'xmlrpc/client'
require 'uri'
require 'net/https'
require 'rubygems'
require 'puppet'
require 'readline'
require 'json'
require 'pp'

module Satellite

  class Server
    SATELLITE_SERVER = 'satellite.ove.local'
    SATELLITE_USER = 'ove_dev'
    SATELLITE_PASS = 'ct9w-X(' #Readline.readline "Enter Satellite password for #{SATELLITE_USER} user: "

    attr_reader :session_key, :connection

    def initialize
      @connection = XMLRPC::Client.new2 "http://#{SATELLITE_SERVER}/rpc/api"
      @session_key = connection.call "auth.login", SATELLITE_USER, SATELLITE_PASS
    end

    def channels
      @channel_obj ||= Channels.new self
    end

    def hosts target_hostname
      return @hosts_from_satellite if @hosts_from_satellite

      all_hosts = connection.call "system.listUserSystems", @session_key
      @hosts_from_satellite  = all_hosts.select { |host|
        host['name'].first.include?(target_hostname)
      }.map { |host| Host.new self, host}
    end

    def hosts_with_channel
      Hash[hosts.map{ |h| h['name']}.zip hosts.map{ |h|  h.base_channel }]
    end
  end

  class Host
    def initialize server, host_hash
      @server = server
      @host_hash = host_hash
    end

    def [] key
      @host_hash[key]
    end

    def base_channel
      @server.connection.call("system.getSubscribedBaseChannel", @server.session_key, @host_hash['id'])['label']
    end

    def child_channels
      @server.connection.call("system.listSubscribedChildChannels", @server.session_key, @host_hash['id']).map { |c| c['label'] }
    end

    def base_channel= channel_label
      if base_channel != channel_label
        @base_channel_updated = true
        raise "Channel #{channel_label} doesn't exist!" unless @server.channels.channel_exists? channel_label
        result = @server.connection.call("system.setBaseChannel", @server.session_key, @host_hash['id'], channel_label)
        raise "Couldn't set base channel of #{self['name']} to #{channel_label}" unless result
      end
      true
    end

    def child_channels= channel_labels
      current_child_channels = child_channels
      unless ((current_child_channels - channel_labels).empty? && (channel_labels - current_child_channels).empty?)
        @child_channels_updated = true
        raise "Channel #{channel_label} doesn't exist!" unless channel_labels.all? { |cl| @server.channels.channel_exists? cl }
        result = @server.connection.call("system.setChildChannels", @server.session_key, @host_hash['id'], channel_labels)
        raise "Couldn't set child channels of #{self['name']} to #{channel_labels.inspect}" unless result
      end
      true
    end

    def current_prefix
      channel_labels = [[base_channel] + [child_channels]].flatten
      min, max = channel_labels.sort.values_at(0, -1)
      (min+max).match(/\A(.*).*(?=.{#{max.length}}\z)\1/m)[1][0..-2]
    end

    def channel_prefix= prefix
      my_current_prefix = current_prefix
      if my_current_prefix != prefix
        subscribed_child_channels = child_channels
        self.base_channel = Satellite::Channels.reprefixed_channel_label my_current_prefix, prefix, base_channel
        reprefixed_child_channels = subscribed_child_channels.map { |c| Satellite::Channels.reprefixed_channel_label my_current_prefix, prefix, c }
        # puts reprefixed_child_channels.inspect
        self.child_channels = reprefixed_child_channels
      end

      if (@base_channel_updated && @child_channels_updated)
        add_note("Channel Prefix Changed", { :prefix => prefix, :stamp => Time.now.to_s }.to_json)
      end
    end

    def add_note subject, body
      @server.connection.call "system.addNote", @server.session_key, @host_hash['id'], subject, body
    end

    def prefix_changes

    end
  end

  class Channels
    DEFAULT_BASE_CHANNEL = 'rhel-x86_64-server-6'

    def self.prefixed_channel_label prefix, channel_label = DEFAULT_BASE_CHANNEL
      return channel_label unless (channel_label =~ /^#{prefix}/).nil?
      (prefix.nil? || prefix == '') ? channel_label : "#{prefix}-#{channel_label}"
    end

    def self.reprefixed_channel_label old_prefix, new_prefix = '', channel_label = DEFAULT_BASE_CHANNEL
      return prefixed_channel_label(new_prefix, channel_label)  if (old_prefix.nil? || old_prefix == '')
      new_prefix = "#{new_prefix}-" unless new_prefix == ''
      channel_label.gsub(/^#{old_prefix}-/,"#{new_prefix}")
    end

    def initialize server
      @server = server
      @refresh = false
    end

    def clone_channel_with_children channel_label, prefix, parent_label = nil
      new_label = "#{prefix}-#{channel_label}"
      if channel_exists? new_label
        # puts "Already cloned #{channel_label} to #{new_label} with parent #{parent_label}"
      else
        @refresh = true
        puts "Trying to clone #{channel_label} to #{new_label} with parent #{parent_label}"
        new_channel_details = { 'name'    => new_label,
                                'label'   => new_label,
                                'summary' => "Clone of #{channel_label} for #{prefix}",
                              }
        new_channel_details['parent_label'] = parent_label if parent_label

        new_channel_id = @server.connection.call "channel.software.clone", @server.session_key, channel_label, new_channel_details, true
      end

      children = @server.connection.call "channel.software.listChildren", @server.session_key, channel_label
      children.each { |child|  clone_channel_with_children child['label'], prefix, new_label }
    end

    def channel_exists? channel_label
      !channel_id(channel_label).nil?
    end

    def channel_id channel_label
      channel = channels.detect { |c| c['label'] == channel_label }
      channel ? channel['id'] : nil
    end

    def channels
      if @channels.nil? or @refresh
        @channels = @server.connection.call "channel.listAllChannels", @server.session_key
      end
      @channels
    end

    def ensure_channel_clone_exists_for prefix
      clone_channel_with_children DEFAULT_BASE_CHANNEL, prefix if prefix && prefix != ''
    end
  end
end