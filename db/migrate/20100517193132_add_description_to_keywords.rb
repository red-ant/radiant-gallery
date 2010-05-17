class AddDescriptionToKeywords < ActiveRecord::Migration
  def self.up     
    add_column :gallery_keywords, :description, :text
  end
  
  def self.down                         
    remove_column :gallery_keywords, :description
  end
end