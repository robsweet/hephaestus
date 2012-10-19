require 'json'

class PuppetModule < ActiveRecord::Base

  serialize :checksums,    JSON
  serialize :dependencies, JSON
  serialize :types,        JSON

  scope :by_shortname, lambda{ |shortname| where("name rlike '[[:<:]]#{shortname}'") unless shortname.nil? }
  scope :by_author_and_shortname, lambda{ |author,shortname| where("name like '#{author}_#{shortname}'") unless shortname.nil? }

  def self.new_from_modulefile modulefile
    attribs = JSON.parse File.read(modulefile)
    self.new attribs
  end

  def author
    name.split(/[\/-]/).first
  end

  def shortname
    name.split(/[\/-]/,2).last
  end

  def full_name
    author + "/" + shortname
  end

  def all_releases_hash
    PuppetModule.by_shortname(shortname).select(:version).map { |pm| {'version' => pm.version } }
  end

  def as_releases_hash
    {
      'name' => shortname,
      'releases' => all_releases_hash,
      'author' => author,
      'version' => version,
      'full_name' => full_name,
      'tag_list' => [],
      'desc' => description,
      'project_url' => project_page,
    }.as_json
  end

{"name"=>"razor",
 "project_url"=>"https://github.com/puppetlabs/puppetlabs-razor",
 "releases"=>
  [{"version"=>"0.1.0"},
   {"version"=>"0.1.1"},
   {"version"=>"0.1.3"},
   {"version"=>"0.1.4"},
   {"version"=>"0.2.0"},
   {"version"=>"0.2.1"}],
 "author"=>"puppetlabs",
 "version"=>"0.2.1",
 "full_name"=>"puppetlabs/razor",
 "tag_list"=>[],
 "desc"=>
  "Puppet Razor module will perform the installation of Razor on an Ubuntu Precise system"}


end