class GalleryKeywordsController < ApplicationController
  
  helper :gallery_items
  before_filter :find_keyword
  
  def edit
  end 
  
  def update
    respond_to do |format|
      if @keyword.update_attributes(params[:keyword])
        flash[:notice] = "Your keyword has been saved below."
        format.html { redirect_to( params[:continue] ? edit_admin_gallery_keyword_path(@gallery, @keyword) : edit_admin_gallery_url(@gallery)) }
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
      format.html { redirect_to(edit_admin_gallery_url(@gallery)) }
      format.xml  { head :ok }
    end
  end

private

  def find_keyword
    @gallery = Gallery.find(params[:gallery_id])
    begin
      @keyword = GalleryKeyword.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      edit_admin_gallery_url(@gallery) 
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_gallery_url
  end 
end