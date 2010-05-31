var Gallery = Gallery || {};

Gallery.EditForm = {

    init: function(popup, link) {    
		
        if (!this.submitHandler) { this.initializeHandler(); }
        var item = link.up('.item');
        popup.down('form').setAttribute('action', link.getAttribute('href'));

        var name = item.down('.label a').innerHTML;
        $('edit-item-name').value = (name === '&nbsp;') ? '': name;
        $('edit-item-credits').value = item.down('.credits').innerHTML;
        $('edit-item-description').value = item.down('.description').innerHTML;
        $('edit-item-url').value = item.down('.url').innerHTML;
        $('edit-item-keywords').value = item.down('.keywords').innerHTML;
    },                                                                         

    initializeHandler: function() {
        this.submitHandler = $('edit-gallery-item-popup').down('form').observe('submit', this.handleFormSubmit);
    },

    open: function(link) {
        var popup = $('edit-gallery-item-popup');
        this.init(popup, link);
        this.show(popup);
    },

    show: function(popup) {  

		popup.show(); 
		if( popup.centerInViewport ){
			popup.centerInViewport();
		} else if( center ){
			center( popup );
		}
		popup.setStyle({
			top: '100px'
		}); 
    },

    close: function() {
        var popup = $('edit-gallery-item-popup');
        popup.hide();
        this.reset(popup);
    },

    reset: function(popup) {
        popup.down('form').setAttribute('action', '');
        $('edit-item-name').value = '';
        $('edit-item-credits').value = '';
        $('edit-item-description').value = '';
        $('edit-item-keywords').value = '';
        $('edit-item-url').value = ''; 
        $('edit-spinner').hide();
        $('edit-submit').show();
    },

    handleFormSubmit: function(event) {
        event.stop();
        $('edit-spinner').show();
        $('edit-submit').hide();
        new Ajax.Request( event.target.getAttribute('action'), {
            method: 'put',
            parameters: {
                'gallery_item[name]': $('edit-item-name').value,
                'gallery_item[credits]': $('edit-item-credits').value,
                'gallery_item[description]': $('edit-item-description').value,
                'gallery_item[keywords]': $('edit-item-keywords').value,    
                'gallery_item[url]': $('edit-item-url').value,    
                authenticity_token: $('authenticity_token').value
            }
        });

    }
};