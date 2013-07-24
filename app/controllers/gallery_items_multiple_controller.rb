class GalleryItemsMultipleController < GalleryItemsController
  
  skip_before_filter :global_authenticate, :only => :swfupload
  
  def new
    respond_to do |format|
      format.html { render :layout => 'gallery_popup' }
    end
  end

end
