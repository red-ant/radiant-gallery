module GalleryItemTags
  #tags available globally, not just on GalleryPages
  include Radiant::Taggable
  
  class GalleryTagError < StandardError; end
  
  tag 'gallery:items' do |tag|
    tag.locals.item = find_item(tag)
    tag.expand
  end
  
  desc %{    
    Usage:
    <pre><code><r:gallery:items:each [order='order' by='by' limit='limit' offset='offset' scope='all|gallery'
    keywords='key1,key2,key3' current_keywords='is|is_not']></r:gallery:items:each></code></pre>
    Valid scopes are 'all' (find all Gallery Items) and 'gallery' (find Items that belong to the current Gallery)
    Iterates through gallery items keywords=(manual entered keywords) and/or current_keywords=(is|is_not) } 
  tag "gallery:items:each" do |tag|
    content = ""
    gallery = find_gallery(tag)
    # TODO
    #items_type = case tag.attr["type"]
    #        when "image"  then 'images'
    #        when "file"   then 'files'              
    #        else
    #          'items'
    #        end
    options = {}
    by = tag.attr['by'] ? tag.attr['by'] : "position"
    unless GalleryItem.columns.find{|c| c.name == by }
      raise GalleryTagError.new("`by' attribute of `each' tag must be set to a valid field name")
    end
    order = (%w[ASC DESC].include?(tag.attr['order'].to_s.upcase)) ? tag.attr['order'] : "ASC"
    options[:order] = "#{GalleryItem.table_name}.#{by} #{order} "    
    options[:limit] = tag.attr['limit'] ? tag.attr['limit'].to_i  : 9999
    options[:offset] = tag.attr['offset'] ? tag.attr['offset'].to_i  : 0
    options[:conditions] = { "#{GalleryItem.table_name}.parent_id" => nil}  
    
    use_slug_as_keyword = tag.attr['use_slug_as_keyword']
    if !tag.attr['keywords'].nil? || !tag.attr['current_keywords'].nil? || use_slug_as_keyword
      keywords = !tag.attr['keywords'].nil? ? tag.attr['keywords'].split(',') : []
      keywords.push(tag.locals.page.slug) if use_slug_as_keyword
      if (tag.attr['current_keywords'] == 'is' || tag.attr['current_keywords'] == 'is_not') && !tag.globals.page.request.parameters['keywords'].nil?
        @current_keywords = tag.globals.page.request.parameters['keywords'].split(',') if !tag.globals.page.request.parameters['keywords'].nil?
        if !@current_keywords.nil? && @current_keywords.length > 0
          keywords.concat(@current_keywords)
        end
      end
      options[:joins] = :gallery_keywords
      options[:conditions].merge!({"gallery_keywords.keyword" => keywords}) if keywords.length > 0              
    end
    
    @page_number = tag.globals.page.request.params["page"] && tag.globals.page.request.params["page"].first.to_i > 1 ? tag.globals.page.request.params["page"].first.to_i : 1
    if !tag.attr['limit'].nil? && tag.attr['offset'].nil?
      options[:offset] = tag.attr['limit'].to_i * (@page_number - 1)      
      @gallery_items_per_page = tag.attr['limit'].to_i
    end
                  
    scope = tag.attr['scope'] ? tag.attr['scope'] : 'gallery'
    raise GalleryTagError.new('Invalid value for attribute scope. Valid values are: gallery, all') unless %[gallery all].include?(scope)  
    items = case scope
      when 'gallery'
        gallery ? gallery.items.find(:all, options) : []
      when 'all'
        GalleryItem.find(:all, options)
    end
    if tag.attr["exclude"]
      options[:conditions].merge({"#{GalleryItem.table_name}.parent_id" => "NOT #{tag.attr["exclude"]}"})
    end
    items.each do |item| 
      tag.locals.item = item
      content << tag.expand
    end unless items.empty?
    content
  end
  
  desc %{    
    Usage:
    <pre><code><r:gallery:item gallery='id' position='position' >...</r:gallery:item></code></pre>
    or
    <pre><code><r:gallery:item gallery='id' position='position' size='size' /></code></pre>
    Selects item at position in gallery }
  tag 'gallery:item' do |tag|     
    tag.locals.item = find_item(tag)    
    tag.expand  
  end
  
  tag 'gallery:item:if_current' do |tag|    
    tag.expand if @current_item
  end
  
  tag 'gallery:item:unless_current' do |tag|    
    tag.expand unless @current_item
  end
  
  tag 'gallery:item:current' do |tag|    
    tag.locals.item = @current_item
    tag.expand
  end
  

  desc %{
    Usage:
    <pre><code><r:gallery:item:name [safe='true']/></code></pre>
    Provides name for current gallery item, safe is to make safe for web }
  tag "gallery:item:name" do |tag|      
    item = find_item(tag)
    name = tag.attr['safe'] ? websafe( item.name ) : item.name
  end 
  
  desc %{
    Usage:
    <pre><code><r:gallery:item:keywords [separator=',' safe='true']/></code></pre>
    Provides keywords for current gallery item, use 
    separator="separator_string" to specify the character between keywords}
  tag "gallery:item:keywords" do |tag|      
    item = find_item(tag)   
    keys = tag.attr['safe'] ? item.keywords { |k| websafe( k ) } : item.keywords
    keys.join( tag.attr['separator'] ? tag.attr['separator'] : ' ' );
  end 

  desc %{
    Usage:
    <pre><code><r:gallery:item:credits /></code></pre>
    Provides the Credits string for current gallery item }
  tag "gallery:item:credits" do |tag|      
    item = find_item(tag)
    item.credits
  end  
  
  desc %{
    }
  tag "gallery:item:if_credits" do |tag|      
    item = find_item(tag)
    
    tag.expand unless item.credits.nil? || item.credits.empty?
  end  
  
  desc %{
    Usage:
    <pre><code><r:gallery:item:url /></code></pre>
    Provides the URL for current gallery item }
  tag "gallery:item:url" do |tag|      
    item = find_item(tag)
    item.url
  end  
  
  desc %{
    Usage:
    <pre><code><r:gallery:item:if_url ><a href="<r:gallery:item:url />">Link</a></r:gallery:item:if_url></code></pre>
    Processes tag  }
  tag "gallery:item:if_url" do |tag|      
    item = find_item(tag)
    
    tag.expand unless item.url.nil? || item.url.empty?
  end  
  
  desc %{
    Usage:
    <pre><code><r:gallery:item:description /></code></pre>
    Provides description for current gallery item }
  tag "gallery:item:description" do |tag|  
    item = find_item(tag)
    item.description
  end
  
  desc %{
    Usage:
    <pre><code><r:gallery:item:link /></code></pre>
    Provides link for current gallery item }
  tag "gallery:item:link" do |tag|  
    item = find_item(tag)
    %{<a href="#{image_path(item)}">#{item.name}</a>}
  end
  
  desc %{
    Usage:
    <pre><code><r:gallery:item:created_at /></code></pre> }
  tag "gallery:item:created_at" do |tag|  
    item = find_item(tag)
    format = tag.attr["format"].to_s
    item.created_at.strftime(format)
  end
  
  desc %{
    Usage:
    <pre><code><r:gallery:item:path /></code></pre>
    Provides path for current gallery item }
  tag "gallery:item:path" do |tag|
    item = find_item(tag)
    image_path(item)
end
  
  desc %{
    Usage:
    <pre><code><r:gallery:item:page_url [page_url='/page-slug/'] /></code></pre>
    Provides page url for current gallery item. 
    *Note:* page_url is optional for specifying a page different to the current }
  tag "gallery:item:page_url" do |tag|
    item = find_item(tag)
    url = tag.attr['base_url'] ? tag.attr['base_url'] : self.url
    url = File.join( url, item.gallery.url( self.base_gallery_id ), "#{item.id}.#{item.extension}/show" )
    url = '/' + url unless url =~ /^\//
    url
  end
  
  desc %{    
    Usage:
    <pre><code><r:gallery:item:if_next>...</r:gallery:item:if_next></code></pre> }
  tag "gallery:item:if_next" do |tag|
    if @current_item
      tag.expand unless @current_item.last?
    end
  end  
  
  tag "gallery:item:if_field_blank" do |tag|
    field = tag.attr['field']
    unless GalleryItem.columns.find{|c| c.name == field }
      raise GalleryTagError.new("`field' attribute of `if_field_blank' tag must be set to a valid field name")
    end
    tag.expand if find_item(tag).send(field).blank?
  end
  
  tag "gallery:item:unless_field_blank" do |tag|
    field = tag.attr['field']
    unless GalleryItem.columns.find{|c| c.name == field }
      raise GalleryTagError.new("`field' attribute of `if_field_blank' tag must be set to a valid field name")
    end
    tag.expand unless find_item(tag).send(field).blank?
  end
  
  tag "gallery:items:next_page" do |tag|
    if @gallery_items_per_page
      text = tag.attr['text'] || "Next"
      conditions = { :parent_id => nil }
      conditions[:gallery_id] = @current_gallery.id if @current_gallery
      count_all = GalleryItem.count(:limit => @gallery_items_per_page, :conditions => conditions)
      if @page_number < (count_all / @gallery_items_per_page.to_f).ceil
        %|<a href="#{tag.render('url')}?page=#{@page_number + 1}">#{text}</a>|
      end
    end
  end
  
  desc %{    
    Usage:
    <pre><code><r:gallery:item:if_prev>...</r:gallery:item:if_prev></code></pre> }
  tag "gallery:item:if_prev" do |tag|
    if @current_item
      tag.expand unless @current_item.position == 1
    end
  end
  
  desc %{
    Usage:
    <pre><code><r:gallery:item:next_page_url [page_url='/page-slug/'] /></code></pre>
    Provides page url for next gallery item.
    *Note:* page_url is optional for specifying a page different to the current }
  tag "gallery:item:next_page_url" do |tag|
    item = find_item(tag)    
    unless item.last?
      next_item = GalleryItem.find(:first, :conditions => ["gallery_id = ? AND position = ? AND parent_id IS NULL", item.gallery.id, item.position + 1, ]) #item.lower_item
      url = tag.attr['base_url'] ? tag.attr['base_url'] : tag.locals.page.url
      url = File.join(url, @current_gallery.url(self.base_gallery_id), "#{next_item.id}.#{next_item.extension}/show") 
      url = '/' + url unless url =~ /^\//
      url
    end
  end
  
  desc %{
    Usage:
    <pre><code><r:gallery:item:prev_page_url [page_url='/page-slug/'] /></code></pre>
    Provides page url for previous gallery item,
    *Note:* page_url is optional for specifying a page different to the current }
  tag "gallery:item:prev_page_url" do |tag|
    item = find_item(tag)
    unless item.position == 0
      prev_item = GalleryItem.find(:first, :conditions => ["gallery_id = ? AND position = ? AND parent_id IS NULL", item.gallery.id, item.position - 1, ]) #item.higher_item
      url = tag.attr['base_url'] ? tag.attr['base_url'] : tag.locals.page.url
      url = File.join(url, @current_gallery.url(self.base_gallery_id), "#{prev_item.id}.#{prev_item.extension}/show")
      url = '/' + url unless url =~ /^\//
      url
    end
  end
  
  desc %{
    Usage:
    <pre><code><r:gallery:item:content_type /></code></pre>
    Provides content-type for current gallery item }
  tag "gallery:item:content_type" do |tag|
    item = find_item(tag)
    item.content_type
  end
  
  desc %{
    Usage:
    <pre><code><r:gallery:item:if_content_type /></code></pre>
    Provides content-type for current gallery item }
  tag "gallery:item:if_content_type" do |tag|
    item = find_item(tag)
    tag.expand if item.content_type == tag.attr['content_type']
  end
  
  desc %{
    Usage:
    <pre><code><r:gallery:item:thumb [width='width' height='height' prefix='preview' geometry='c84x84'] /></code></pre> 
    Provides a sized image for current gallery item.
    Current size values are: icon, small, medium, large }
  tag 'gallery:item:thumb' do |tag|    
    item = find_item(tag)
    options = {}
    [:width, :height, :prefix, :geometry].each{|symbol| options[symbol] = tag.attr[symbol.to_s] if tag.attr[symbol.to_s] }
    image_path(item.thumb(options))
  end
  
  tag 'gallery:children' do |tag|
    gallery = find_gallery(tag)
    tag.expand
  end

protected
  def websafe( string )
    string.gsub(/[\s~\.,:;+=]+/, '_').downcase
  end
  
  def find_item(tag)
    if tag.locals.item 
      tag.locals.item
    elsif tag.attr['position'] # direct access to item; not in a gallery:items:each loop      
      gallery = find_gallery(tag)      
      position = tag.attr['position']
      position = 1 if tag.attr['position'] == 'first'
      position = rand(gallery.items.count) if tag.attr['position'] == 'random'
      position = gallery.items.count if tag.attr['position'] == 'last'
      i = gallery.items.find_by_position(position.to_i)    
    end
  end
  
  def image_path(image)
    response.template.send(:path_to_image, image.public_filename)
  end

end
