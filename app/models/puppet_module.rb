require 'json'

class PuppetModule < ActiveRecord::Base

  serialize :checksums,    JSON
  serialize :dependencies, JSON
  serialize :types,        JSON

  scope :by_shortname, lambda{ |shortname| where("name rlike '[[:<:]]#{shortname}'") if shortname }
  scope :by_author_and_shortname, lambda{ |author,shortname| where("name like '#{author}_#{shortname}'") if shortname }
  scope :by_version, lambda{ |version| where(:version => version) if version }

  validates_uniqueness_of :name, :scope => :version, :case_sensitive => false, :message => "A module with this name and version already exists"

  def self.find_or_mirror author, shortname, version = nil
    target_module = PuppetModule.by_author_and_shortname(author, shortname).by_version(version).first
    return target_module if target_module

    puts  "Can't find module for #{author}/#{shortname} (ver. #{version || '?'}) locally.  Time to mirror!"
    RemoteForge.new.mirror_module_with_deps author, shortname
    PuppetModule.by_author_and_shortname(author, shortname).by_version(version).first 
  end

  def self.tar_binary
    File.exist?("/usr/bin/gnutar") ? '/usr/bin/gnutar' : '/bin/tar'
  end

  def self.new_from_module_tarball module_tarball
    metadata = `#{tar_binary} -xzf #{module_tarball} --wildcards --no-anchored '*/metadata.json' -O`
    self.new JSON.parse( metadata )
  end

  def self.new_from_metadata modulefile
    attribs = JSON.parse File.read(modulefile)
    self.new attribs
  end

  # def self.find_or_mirror author, shortname
  #   target_module = PuppetModule.by_author_and_shortname(author, shortname).first
  #   return target_module if target_module

  #   RemoteForge.new.mirror_module_with_deps author, shortname
  #   PuppetModule.by_author_and_shortname(author, shortname).first
  # end

  def author
    name.split(/[\/-]/).first
  end

  def shortname
    name.split(/[\/-]/,2).last
  end

  def filename
    "#{Hephaestus::Application.config.local_releases_path}/#{author[0]}/#{author}/#{author}-#{shortname}-#{version}.tar.gz"
  end

  def file_url
    filename.gsub /#{Rails.root}/, ''
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
    deps_hash = nonrecursive_dependencies_hash
    while !deps_left_to_fetch(deps_hash).empty?
      # puts "Missing deps_hash entry for #{deps_left_to_fetch(deps_hash).join ', '}"
      deps_left_to_fetch(deps_hash).each do |depmod_full_name|
        depmod = PuppetModule.find_or_mirror *depmod_full_name.split('/')
        if depmod
          deps_hash.merge! depmod.nonrecursive_dependencies_hash
        end
      end
    end
    deps_hash
  end


  protected

  def nonrecursive_dependencies_hash
    # puts "Building deps hash for #{full_name}"
    deps_hash = { full_name => [] }

    all_releases.each do |rel|
      rel_deps = rel.dependencies.map { |ver_dep_hash| [ver_dep_hash['name'], ver_dep_hash['version_requirement']]}
      deps_hash[full_name] << { "dependencies" => rel_deps,
                                "version" => rel.version,
                                "file" => file_url }
    end
    # pp deps_hash
    # puts "-" * 80
    deps_hash
  end

  def deps_left_to_fetch the_hash
    foo = the_hash.values.map do |versions_array|
      versions_array.map do |version_hash|
        version_hash['dependencies'].map { |deps_array| deps_array[0] }
      end
    end.flatten.uniq - the_hash.keys
    # pp foo
    foo
  end

end
