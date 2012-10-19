class LocalForge
  class << self
    def forge_path
      Rails.root + "local_releases"
    end

    def module_exists? name

    end
  end
end