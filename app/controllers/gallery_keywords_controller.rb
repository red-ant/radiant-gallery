class GalleryKeywordsController < ApplicationController
  
  helper :gallery_items
  before_filter :find_keyword, :except => [:new, :create]
  
  def show
  end
  
  def new
    @keyword = GalleryKeyword.new
  end

  def create
    @gallery = Gallery.find(params[:gallery_id]) 
    @keyword = GalleryKeyword.new(params[:gallery])
    
    respond_to do |format|
      if @keyword.save && @gallery.gallery_keywords << @keyword
        flash[:notice] = "Your keyword has been saved below." 
        format.html { redirect_to( params[:continue] ? edit_admin_gallery_keyword_path(@gallery, @keyword) : admin_gallery_url(@gallery)) }
      else
        flash[:error] = "Validation errors occurred while processing this form. Please take a moment to review the form and correct any input errors before continuing."
        format.html { render :action => 'new' }
      end
    end
  end  
  
  def edit
  end 
  
  def update
    respond_to do |format|
      if @keyword.update_attributes(params[:keyword])
        flash[:notice] = "Your keyword has been saved below."
        format.html { redirect_to( params[:continue] ? edit_admin_gallery_keyword_path(@gallery, @keyword) : admin_gallery_url(@gallery)) }
      else
        flash[:error] = "Validation errors occurred while processing this form. Please take a moment to review the form and correct any input errors before continuing."
        form.html { render(:action => 'edit') }
      end
    end
  end
  
  def destroy
    @keyword.destroy
    flash[:notice] = "Keyword was successfully removed."
    
    respond_to do |format|
      format.html { redirect_to(admin_galleries_url) }
      format.xml  { head :ok }
    end
  end

private
  
  def find_keyword
    @gallery = Gallery.find(params[:gallery_id]) 
    @keyword = @gallery.gallery_keywords.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_galleries_url
  end 
end