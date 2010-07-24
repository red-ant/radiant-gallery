ActionController::Routing::Routes.draw do |map|
  # FIME: it doesn't work with namespace admin and without :name_prefix and path_prefix (only on production). :(
  #map.namespace(:admin) do |admin|
    map.resources :galleries,
      :name_prefix =>'admin_',
      :path_prefix => 'admin',
      :member     => {
        :clear_thumbs => :get,
        :reorder => :get, 
        :update_order => :post
      },
      :collection => { 
        :children => :get,
        :reorder => :get, 
        :update_order => :post 
      } do |galleries|
        galleries.resources :children,    :controller => 'galleries', :path_prefix => '/admin/galleries/:parent_id'
        galleries.resources :items,       :controller => 'gallery_items', :member => { :move => :put }
        galleries.resources :importings,  :controller => 'gallery_importings', :member => { :import => :put }
        galleries.resources :keywords,    :controller => 'gallery_keywords', :only => [ :edit, :update, :destroy ]
    end
end  