module GalleryTags
  #tags available globally, not just on GalleryPages   
  include Radiant::Taggable
  
  class GalleryTagError < StandardError; end
  
  tag "galleries" do |tag| 
    tag.expand
  end
  
  desc %{    
    Usage:
    <pre><code><r:galleries:each [order='order' by='by' limit='limit' 
      offset='offset' level='top|current|bottom|all' keywords='key1,key2,key3' 
      current_keywords='is|is_not']>...</r:galleries:each></code></pre>
      Iterates through all gallery items keywords=(manual entered keywords) 
      and/or current_keywords=(is|is_not) }
  tag "galleries:each" do |tag|
    content = ''
    options = {}
    options[:conditions] = {:hidden => false, :external => false}
    
    level = tag.attr['level'] ? tag.attr['level'] : 'all'
    raise GalleryTagError.new('Invalid value for attribute level. Valid values are: current, top, bottom') unless %[current top bottom all].include?(level)
    case level
    when 'current'
      options[:conditions][:parent_id] = if @current_gallery
        @current_gallery.id
      elsif self.base_gallery
        self.base_gallery
      else
        nil
      end
    when 'top'
      options[:conditions][:parent_id] = nil
    when 'bottom'
      options[:conditions][:children_count] = 0
    end  

    by = tag.attr['by'] ? tag.attr['by'] : "position"
    unless Gallery.columns.find{|c| c.name == by }
      raise GalleryTagError.new("`by' attribute of `each' tag must be set to a valid field name")
    end  
    
    if !tag.attr['keywords'].nil? || !tag.attr['current_keywords'].nil?                                                                                                                                  
      keywords = !tag.attr['keywords'].nil? ? tag.attr['keywords'].split(',') : []
      if (tag.attr['current_keywords'] == 'is' || tag.attr['current_keywords'] == 'is_not') && !tag.globals.page.request.parameters['keywords'].nil?
        @current_keywords = tag.globals.page.request.parameters['keywords'].split(',') if !tag.globals.page.request.parameters['keywords'].nil?
        if !@current_keywords.nil? && @current_keywords.length > 0
          keywords.concat(@current_keywords)
        end
      end
      options[:joins] = :gallery_keywords
      options[:conditions].merge!({"gallery_keywords.keyword" => keywords}) if keywords.length > 0              
    end
    
    options[:limit] = tag.attr['limit'] ? tag.attr['limit'].to_i : 9999
    options[:offset] = tag.attr['offset'] ? tag.attr['offset'].to_i  : 0
    order = (%w[ASC DESC].include?(tag.attr['order'].to_s.upcase)) ? tag.attr['order'] : "ASC"
    options[:order] = "#{by} #{order}"  
    galleries = Gallery.find(:all, options).uniq unless @current_keywords.nil? && tag.attr['current_keywords'] == 'is'
    
    if !@current_keywords.nil? && tag.attr['current_keywords'] == 'is_not' && galleries.length > 0                                                   
      options.merge!(:conditions => ['galleries.id NOT IN (?) AND hidden =? AND external =?', galleries, false, false])   
      galleries = Gallery.find(:all, options).uniq
    end
    
    galleries.each do |gallery|
      tag.locals.gallery = gallery
      content << tag.expand
    end unless @current_keywords.nil? && tag.attr['current_keywords'] == 'is' 
    content
  end
  
  desc %{    
    Usage:
    <pre><code><r:gallery [id='id'] [name='name'] [keywords='key1, key2, key3']>...</r:gallery></code></pre>
    Selects current gallery }
  tag "gallery" do |tag|
    tag.locals.gallery = find_gallery(tag)
    tag.expand unless tag.locals.gallery.nil? && tag.attr['fail_silently']
  end
  
  desc %{    
    Usage:
    <pre><code><r:gallery:if_current>...render content...</r:gallery:if_current></code></pre> 
    If gallery is current continue }  
  tag 'gallery:if_current' do |tag|    
    tag.expand if @current_gallery && @current_gallery == tag.locals.gallery
  end  

  desc %{    
    Usage:
    <pre><code><r:gallery:unless_current>...render content...</r:gallery:unless_current></code></pre> 
    Unless gallery is current continue }  
  tag 'gallery:unless_current' do |tag|    
    tag.expand unless @current_gallery && @current_gallery == tag.locals.gallery
  end

  desc %{    
    Usage:
    <pre><code><r:gallery:current>...render content...</r:gallery:current></code></pre> 
    For the current gallery content }  
  tag 'gallery:current' do |tag|    
    tag.locals.gallery = @current_gallery
    tag.expand
  end

  desc %{    
    Usage:
    <pre><code><r:gallery:keywords:if_current>...render content...</r:gallery:keywords:if_current></code></pre> 
    If gallery keywords are available continue }
  tag 'gallery:keywords:if_current' do |tag|    
    tag.expand if @current_keywords
  end  

  desc %{    
    Usage:
    <pre><code><r:gallery:keywords:unless_current>...render content...</r:gallery:keywords:unless_current></code></pre> 
    Unless gallery keywords are available continue }
  tag 'gallery:keywords:unless_current' do |tag|    
    tag.expand unless @current_keywords
  end
  
  desc %{                 
    Usage:
    <pre><code><r:gallery:keywords:current /></code></pre>
    Provides keywords for current and children galleries, use
    separator="separator_string" to specify the character between keywords }  
  tag 'gallery:keywords:current' do |tag|
    gallery = tag.locals.gallery        
    content = ""        
    joiner = tag.attr['separator'] ? tag.attr['separator'] : ' '
    gallery.gallery_keywords.find(:all, :conditions => { :keyword => @current_keywords }).uniq.each do | keyword |
      tag.locals.uniq_keywords = keyword
      content << tag.expand
    end
    content.blank? ? @current_keywords.join( joiner ) : content
  end
  
  desc %{    
    Usage:
    <pre><code><r:gallery:name [safe='true']/></code></pre>
    Provides name for current gallery, safe is to make safe for web }
  tag "gallery:name" do |tag|
    gallery = tag.locals.gallery
    name = tag.attr['safe'] ? websafe( gallery.name ) : gallery.name
  end

  desc %{
    Usage:
    <pre><code><r:gallery:slug/></code></pre>
    Provides slug for current gallery. Use this to append on the url of your gallery root page (e.g. in sidebar or sitemap }
  tag "gallery:slug" do |tag|
    gallery = tag.locals.gallery
    gallery.slug
  end 
  
  desc %{                 
    Usage:
    <pre><code><r:gallery:keywords [separator=',' safe='true']/></code></pre>
    Provides keywords for current and children galleries, use
    separator="separator_string" to specify the character between keywords }
  tag "gallery:keywords" do |tag|
    gallery = tag.locals.gallery     
    keys = tag.attr['safe'] ? gallery.keywords{ |k| websafe(k) } : gallery.keywords
    keys.join( tag.attr['separator'] ? tag.attr['separator'] : ' ' )
    tag.expand
  end                            

  desc %{
    Usage:
    <pre><code><r:gallery:keywords:each /></code></pre>
    Loops over each keywords for current and children galleries }
  tag "gallery:keywords:each" do |tag|
    content =''
    gallery = tag.locals.gallery
    gallery.gallery_keywords.uniq.each do |key|
      tag.locals.uniq_keyword = key
      content << tag.expand
    end
    content
  end  
  
  desc %{
    Usage:
    <pre><code><r:gallery:keywords:keyword [safe='true']/></code></pre>
    Get the keyword of the current gallery:keywords loop } 
  tag 'gallery:keywords:keyword' do |tag|
    keyword = tag.locals.uniq_keyword.keyword
    k = tag.attr['safe'] ? websafe( keyword ) : keyword
  end
       
  desc %{
    Usage:
    <pre><code><r:gallery:keywords:description /></code></pre>
    Get the description for the current keyword in gallery:keywords loop } 
  tag 'gallery:keywords:description' do |tag|
    tag.locals.uniq_keyword.description
  end
  
  desc %{
    Usage:
    <pre><code><r:gallery:keywords:link [*options] [current_gallery='use']/></code></pre>
    Get the keyword and creates a link for the current gallery:keywords loop 
    options are rendered inline as key:value pairs i.e. class='' id='', etc.}    
  tag 'gallery:keywords:link' do |tag|
    keyword = tag.locals.uniq_keyword.keyword
    options = tag.attr.dup
    attributes = options.inject('') { |s, (k, v)| s << %{#{k.downcase}="#{v}" } }.strip
    attributes = " #{attributes}" unless attributes.empty?
    gallery_url = File.join( tag.render('url'), tag.attr['current_gallery'] ? tag.locals.gallery.slug : '' ).gsub(/\/$/,'')
    %{<a href="#{gallery_url}?keywords=#{keyword.gsub(/[\s~\.:;+=]+/, '_')}"#{attributes}>#{keyword}</a>}
  end
  
  desc %{                 
    Usage:
    <pre><code><r:gallery:keywords:current /></code></pre>
    Provides keywords for current and children galleries, use
    separator="separator_string" to specify the character between keywords }  
  tag 'gallery:keywords:current' do |tag|
    gallery = tag.locals.gallery        
    content = ""        
    joiner = tag.attr['separator'] ? tag.attr['separator'] : ' '
    gallery.gallery_keywords.find(:all, :conditions => { :keyword => @current_keywords }).uniq.each do | key |
      tag.locals.uniq_keyword = key
      content << tag.expand
    end
    key = content.blank? ? @current_keywords.join( joiner ) : content
  end
  
  desc %{
     Usage:
     <pre><code><r:gallery:breadcrumbs /></code></pre>
     Breadcrumb to the current gallery 
  }  
  tag 'gallery:breadcrumbs' do |tag|
    gallery = find_gallery(tag)
    breadcrumbs = []
    gallery.ancestors_from(self.base_gallery_id).unshift(gallery).each do |ancestor|
      if @current_gallery == ancestor && @current_item.nil?
        breadcrumbs << %|#{ancestor.name}|
      else
        ancestor_absolute_url = File.join(tag.render('url'), ancestor.url(self.base_gallery_id))
        breadcrumbs.unshift(%|<a href="#{ancestor_absolute_url}">#{ancestor.name}</a>|)
      end
    end
    separator = tag.attr['separator'] || ' &gt; '
    breadcrumbs.join(separator)
  end
  
  desc %{    
    Usage:
    <pre><code><r:gallery:description /></code></pre>
    Provides description for current gallery }
  tag "gallery:description" do |tag|
    gallery = tag.locals.gallery
    gallery.description
  end  

  desc %{    
    Usage:
    <pre><code><r:gallery:location /></code></pre>
    Provides location for current gallery }
  tag "gallery:location" do |tag|
    gallery = tag.locals.gallery
    gallery.location
  end
  
  desc %{    
    Usage:
    <pre><code><r:gallery:children:each [order='order' by='by' limit='limit' offset='offset'
    keywords='key1,key2,key3' current_keywords='is|is_not']>...</r:gallery:children:each></code></pre>
    Iterates through all gallery items keywords=(manual entered keywords) and/or current_keywords=(is|is_not) }
  tag "gallery:children:each" do |tag|
    content = ""
    gallery = find_gallery(tag)
    options = {}
    options[:conditions] = {:hidden => false, :external => false}
    by = tag.attr['by'] ? tag.attr['by'] : "position"
    unless Gallery.columns.find{|c| c.name == by }
      raise GalleryTagError.new("`by' attribute of `each' tag must be set to a valid field name")
    end   
               
    if !tag.attr['keywords'].nil? || !tag.attr['current_keywords'].nil?                                                                                                                                  
      keywords = !tag.attr['keywords'].nil? ? tag.attr['keywords'].split(',') : []
      if (tag.attr['current_keywords'] == 'is' || tag.attr['current_keywords'] == 'is_not') && !tag.globals.page.request.parameters['keywords'].nil?
        @current_keywords = tag.globals.page.request.parameters['keywords'].split(',') if !tag.globals.page.request.parameters['keywords'].nil?
        if !@current_keywords.nil? && @current_keywords.length > 0
          keywords.concat(@current_keywords)
        end
      end
      options[:joins] = :gallery_keywords
      options[:conditions].merge!({"gallery_keywords.keyword" => keywords}) if keywords.length > 0              
    end
    
    options[:limit] = tag.attr['limit'] ? tag.attr['limit'].to_i : 9999
    options[:offset] = tag.attr['offset'] ? tag.attr['offset'].to_i  : 0
    order = (%w[ASC DESC].include?(tag.attr['order'].to_s.upcase)) ? tag.attr['order'] : "ASC"
    options[:order] = "#{by} #{order}"   
    galleries = gallery.children.find(:all, options).uniq unless @current_keywords.nil? && tag.attr['current_keywords'] == 'is'
    if !@current_keywords.nil? && tag.attr['current_keywords'] == 'is_not' && galleries.length > 0                                                   
      options.merge!(:conditions => ['galleries.id NOT IN (?) AND hidden =? AND external =?', galleries, false, false])   
      galleries = gallery.children.find(:all, options).uniq
    end                                    
    galleries.each do |sub_gallery| 
      tag.locals.gallery = sub_gallery
      content << tag.expand      
    end unless @current_keywords.nil? && tag.attr['current_keywords'] == 'is'
    content
  end
  
  desc %{    
    Usage:
    <pre><code><r:gallery:if_children>...</r:gallery:if_children></code></pre> }
  tag "gallery:if_children" do |tag|
    gallery = find_gallery(tag)  
    tag.expand unless gallery.children.empty?
  end
  
  desc %{    
    Usage:
    <pre><code><r:gallery:unless_children>...</r:gallery:unless_children></code></pre> }
  tag "gallery:unless_children" do |tag|
    gallery = find_gallery(tag)  
    tag.expand if gallery.children.empty?
  end
  
  desc %{    
    Usage:
    <pre><code><r:gallery:if_galleries>...</r:gallery:if_galleries></code></pre> }
  tag "gallery:if_galleries" do |tag|
    gallery = find_gallery(tag)
    if gallery && !gallery.children.empty?
      tag.expand
    elsif gallery && gallery.children.empty?
      nil
    elsif Gallery.count(:conditions => {:parent_id => nil, :hidden => false})
      tag.expand
    end
  end
  
  desc %{    
    Usage:
    <pre><code><r:gallery:unless_galleries>...</r:gallery:unless_galleries></code></pre> }
  tag "gallery:unless_galleries" do |tag|
    gallery = find_gallery(tag)
    if gallery && gallery.children.empty?
      tag.expand
    elsif gallery && !gallery.children.empty?
      nil
    elsif Gallery.count(:conditions => {:parent_id => nil, :hidden => false})
      nil
    end
  end
  
  desc %{    
    Usage:
    <pre><code><r:gallery:if_items>...</r:gallery:if_items></code></pre> }
  tag "gallery:if_items" do |tag|
    gallery = find_gallery(tag)    
    tag.expand if gallery && !gallery.items.empty?
  end
  
  desc %{    
    Usage:
    <pre><code><r:gallery:unless_items>...</r:gallery:unless_items></code></pre> }
  tag "gallery:unless_items" do |tag|
    gallery = find_gallery(tag)  
    tag.expand if !gallery || gallery.items.empty?
  end
  
  desc %{
    Usage:
    <pre><code><r:gallery:children_size /></code></pre>
    Provides the number of children for current gallery }
  tag "gallery:children_size" do |tag|  
    gallery = find_gallery(tag)
    gallery.children.size    
  end
  
  desc %{
    Usage:
    <pre><code><r:gallery:items_size /></code></pre>
    Provides the number of items for current gallery }
  tag "gallery:items_size" do |tag|  
    gallery = find_gallery(tag)
    gallery.items.size    
  end
  

  protected

  def websafe( string )
    string.gsub(/[\s~\.,:;+=]+/, '_').downcase
  end 
  
  def find_gallery(tag)  
    if tag.locals.gallery
      tag.locals.gallery 
    elsif tag.attr["name"]
      Gallery.find_by_name tag.attr["name"]
    elsif tag.attr["id"] 
      Gallery.find_by_id tag.attr["id"] 
    elsif @current_gallery
      @current_gallery
    elsif tag.locals.page.base_gallery
      tag.locals.page.base_gallery
    end
  end
  
end
