var Gallery = Gallery || {};

// prepare a cut down version of the rich text editor for the popups
tinyMCE.init({
	editor_selector: 'mceEditor',
	editor_deselector: 'noMceEditor',
	mode: 'textareas',
	theme: 'advanced',
	theme_advanced_buttons1: 'bold,italic,underline,strikethrough,|,bullist,numlist,charmap,|,undo,redo,|,link,unlink,cleanup,help,code,',
	theme_advanced_buttons2: '',
	theme_advanced_buttons3: '',
	theme_advanced_toolbar_location: 'top',
	theme_advanced_toolbar_align: 'left',
	relative_urls: false
});

Gallery.EditForm = {

	init: function(popup, link) {

		if (!this.submitHandler) {
			this.initializeHandler();
		}

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
		this.submitHandler = $('edit-gallery-item-popup').down('form').observe('submit', this.handleFormSubmit.bind(this));
	},

	open: function(link) {
		var popup = $('edit-gallery-item-popup');
		this.init(popup, link);
		this.show(popup);
		this.showWysiwyg();
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
		this.hideWysiwyg();
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

	toggleWysiwyg: function(){
		tinyMCE.execCommand('mceToggleEditor', false, 'edit-item-description');
	},

	showWysiwyg: function(){
		tinyMCE.execCommand('mceAddControl', false, 'edit-item-description');
	},

	hideWysiwyg: function(){
		tinyMCE.execCommand('mceRemoveControl', false, 'edit-item-description');
	},

	handleFormSubmit: function(event) {
		event.stop();
		if(!$('edit-item-description').visible()) {
			this.hideWysiwyg();
		}
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