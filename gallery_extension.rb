require 'tempfile'           
require 'open-uri'

require_dependency Radiant::Version.to_s.to_f < 0.8 ? 'application' : 'application_controller'   
require_dependency 'exifr/jpeg'
require_dependency 'exifr/tiff'

class GalleryExtensionError < StandardError; end

class GalleryExtension < Radiant::Extension
  version RadiantGallery::Version.to_s
  description "Allows to manage list of files/images grouped into galleries"
  url "http://eightsquarestudio.com/blog/2010/01/01/radiant-gallery/"
  
  def activate
    init       
    if Radiant::Version.to_s.to_f < 0.9 
      tab_options = {:visibility => [:all]}
      
      if Radiant::Config.table_exists?
        Radiant::Config["gallery.gallery_based"] == 'true' ? tab_options[:before] = "Pages" : tab_options[:after] = "Layouts"
      end
      
      admin.tabs.add("Galleries", "/admin/galleries", tab_options)      
    else
      
      tab "Content" do
         add_item("Galleries", "/admin/galleries", {:visibility => [:all]}) 
      end      
    end    

    admin.page.edit.add :layout_row, 'base_gallery' if admin.respond_to?(:page)
  end      
  
  def init
    Page.send(:include, PageExtensionsForGallery, GalleryTags, GalleryItemTags, GalleryItemInfoTags, GalleryLightboxTags)
    UserActionObserver.instance
    UserActionObserver.class_eval do
      observe Gallery, GalleryItem
    end
    GalleryPage
    GalleryCachedPage
    load_configuration
    load_content_types
    if Radiant::Config["gallery.gallery_based"] == 'true'
      Admin::WelcomeController.class_eval do
        def index
          redirect_to admin_galleries_path
        end
      end
    end
  end
  
  def load_configuration    
    load_yaml('gallery') do |configurations|      
      configurations.each do |key, value|
        if value.is_a?(Hash)
          value = value.collect{|k, v| "#{k}=#{v}"}.join(',')
        end
        Radiant::Config["gallery.#{key}"] = value
      end
    end
  end
  
  def load_content_types
   load_yaml('content_types') do |content_types|
     content_types.each do |name, attributes|
       attributes["extensions"].each do |extension|
         GalleryItem::KnownExtensions[extension] = {
           :content_type => name,
           :icon => attributes["icon"]
         }
       end
     end
   end
  end
   
private 
  
  def load_yaml(filename)
    config_path = File.join(RAILS_ROOT, 'config', 'extensions', 'gallery')
    filename = File.join(config_path, "#{filename}.yml")
    raise GalleryExtensionError.new("GalleryExtension error: #{filename} doesn't exist. Run the install task and try again.") unless File.exists?(filename)
    data = YAML::load_file(filename)
    yield(data)
  end
    
end