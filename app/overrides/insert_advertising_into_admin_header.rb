Deface::Override.new(:virtual_path => "spree/admin/shared/_menu",
                     :name => "advertising_admin_tab",
                     :insert_bottom => "[data-hook='admin_tabs']",
                     :text => "<%= tab(:advertising, :icon => 'icon-file', :url => admin_product_ad_channels_path) %>",
                     :disabled => false)
