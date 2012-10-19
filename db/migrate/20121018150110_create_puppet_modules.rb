class CreatePuppetModules < ActiveRecord::Migration
  def change
    create_table :puppet_modules do |t|
      t.string :name
      t.string :version
      t.string :source
      t.string :author
      t.string :license
      t.string :summary
      t.string :project_page
      t.text   :description
      t.text   :dependencies
      t.text   :types
      t.text   :checksums
      t.timestamps
    end
  end
end
