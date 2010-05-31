class AddLocationToGallery < ActiveRecord::Migration
  def self.up     
    add_column :galleries, :location, :string
  end
  
  def self.down                         
    remove_column :galleries, :location
  end
end