require 'json'

class PuppetModule < ActiveRecord::Base

  serialize :checksums,    JSON
  serialize :dependencies, JSON
  serialize :types,        JSON

  scope :by_shortname, lambda{ |shortname| where("name rlike '[[:<:]]#{shortname}'") unless shortname.nil? }
  scope :by_author_and_shortname, lambda{ |author,shortname| where("name like '#{author}_#{shortname}'") unless shortname.nil? }

  validates_uniqueness_of :name, :scope => :version, :case_sensitive => false

  def self.new_from_module module_tarball
    metadata = `/usr/bin/tar -xzf #{module_tarball} --include '*/metadata.json' -O`
    self.new JSON.parse( metadata )
  end

  def self.new_from_metadata modulefile
    attribs = JSON.parse File.read(modulefile)
    self.new attribs
  end

  def author
    name.split(/[\/-]/).first
  end

  def shortname
    name.split(/[\/-]/,2).last
  end

  def filename
    "#{Hephaestus::Application.config.local_releases_path}/#{author[0]}/#{author}/#{author}-#{shortname}-#{version}.tar.gz"
  end

  def full_name
    author + "/" + shortname
  end

  def all_releases
    PuppetModule.by_shortname(shortname)
  end

  def all_releases_hash
    all_releases.select(:version).map { |pm| {'version' => pm.version } }
  end

  def releases_hash
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

  def dependencies_hash
    deps_hash = { full_name => [] }

    all_releases.each do |rel|
      deps_hash[full_name] << { "dependencies" => rel.dependencies,
                                "version" => rel.version,
                                "file" => filename }
    end
  end

end