class AddCreditsFieldToGalleryItem < ActiveRecord::Migration
  def self.up
    add_column :gallery_items, :credits, :string
  end

  def self.down
    remove_column :gallery_items, :credits
  end
end
