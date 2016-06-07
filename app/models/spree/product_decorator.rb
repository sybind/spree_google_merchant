module Spree
  Product.class_eval do
    scope :google_merchant_scope, includes(:taxons, {:master => :images}).includes(:product_properties)
    scope :amazon_ads, joins([{:product_properties => :property}, {:master => :stock_items}]).where("not (spree_properties.name = 'brand' and spree_product_properties.value = 'Loftus') and spree_stock_items.count_on_hand <> 0").where("imagesize >= 500").includes(:taxons, {:master => [:images, :stock_items]}).includes(:product_properties).group(:id)
    scope :ebay_ads, joins([{:product_properties => :property}, {:master => :stock_items}]).where("spree_stock_items.count_on_hand <> 0").where("imagesize >= 300").includes(:taxons, {:master => [:images, :stock_items]}).includes(:product_properties).group(:id)

    def first_property(property_name)
      value = self.property(property_name)
      if value.kind_of?(Array) && value.length > 0
        value = value[0]
      end
      value
    end

    def google_merchant_description
      self.description
    end

    def google_merchant_title
      self.name
    end

    # <g:google_product_category> Apparel & Accessories > Clothing > Dresses (From Google Taxon Map)
    def google_merchant_product_category
      # self.first_property(:gm_product_category) || Spree::GoogleMerchant::Config[:product_category]
      self.gm_product_category
    end

    def google_merchant_product_type     
      return unless taxons.any?
      # TODO: fix this; right now it only takes the 1st taxon, and ignores the rest
      taxons.last.self_and_ancestors.map(&:name).join(" > ")
    end

    # <g:condition> new | used | refurbished
    def google_merchant_condition
      'new'
    end

    # <g:availability> in stock | available for order | out of stock | preorder
    def google_merchant_availability
      # self.master.stock_items.sum(:count_on_hand) > 0 ? 'in stock' : 'out of stock'
      'in stock'
    end

    def google_merchant_quantity
      self.master.stock_items.sum(:count_on_hand)
    end

    def google_merchant_image_link   
      self.image.attachment.url.gsub(/\?+[0-9]+/i, '')
    end

    def google_merchant_brand
      # self.first_property(:brand)
      self.property("Brand")
    end

    # <g:price> 15.00 USD
    def google_merchant_price(currency)     
      format("%.2f %s", self.price_in(currency).amount.to_f, currency).to_s
    end

    # <g:sale_price> 15.00 USD
    def google_merchant_sale_price
      unless self.first_property(:gm_sale_price).nil?
        format("%.2f %s", self.first_property(:gm_sale_price), self.currency).to_s
      end
    end

    # <g:sale_price_effective_date> 2011-03-01T13:00-0800/2011-03-11T15:30-0800
    def google_merchant_sale_price_effective_date
      unless self.first_property(:gm_sale_price_effective).nil?
        return # TODO
      end
    end

    def google_merchant_id
      self.id
    end

    # <g:gtin> 8-, 12-, or 13-digit number (UPC, EAN, JAN, or ISBN)
    def google_merchant_gtin
      self.master.gtin rescue self.property("UPC")
    end

    # <g:mpn> Alphanumeric characters
    def google_merchant_mpn
      self.property("MPN").gsub(/[^0-9a-z ]/i, '')
    end

    # <g:gender> Male, Female, Unisex
    def google_merchant_gender
      value = self.first_property(:gender)
      return unless value.present?
      determine_gender(value)
    end

    def determine_gender(string)
      if ['girl','women','woman','female'].select{|v|string.downcase.include? v}.any?
        'female'
      elsif ['boy','men','man','male'].select{|v|string.downcase.include? v}.any?
        'male'
      else
        'unisex'
      end
    end

    # <g:age_group> Adult, Kids
    def google_merchant_age_group
      value = self.first_property(:agegroup)
      return unless value.present?
      value.gsub('Adults','Adult')
    end

    # <g:color>
    def google_merchant_color
      self.first_property(:color)
    end

    # <g:size>
    def google_merchant_size
      self.first_property(:size)
    end

    # <g:adwords_grouping> single text value
    def google_merchant_adwords_group
      self.first_property(:gm_adwords_group)
    end

    # <g:shipping_weight> # lb, oz, g, kg.
    def google_merchant_shipping_weight
      return unless self.weight.present?
      weight_units = 'oz'       # need a configuration parameter here
      format("%s %s", self.weight, weight_units)
    end

    # <g:adult> TRUE | FALSE
    def google_merchant_adult
      self.first_property(:gm_adult) unless self.first_property(:gm_adult).nil?
    end

    ## Amazon Listing Methods
    def amazon_category
      self.first_property(:category)
    end

    def amazon_title
      self.name
    end

    def amazon_link
      self.url
    end

    def amazon_sku
      self.sku
    end

    def amazon_price
      self.price.to_s
    end

    def amazon_image
      self.max_image_url
    end

    def amazon_upc
      self.upc
    end

    def amazon_brand
      self.first_property(:brand)
    end

    def amazon_recommended_browse_node
      # case self.property(:group)
      # when "Costumes"
      #   case self.property(:gender)
      #   when "Boys"

      #   when "Girls"

      #   when "Men"

      #   when "Women"
          
      # if self.property(:group) == "Costumes"
      #   if self.property(:gender) == "Boys"
      #     727631011
      #   elsif self.property(:gender) == "Girls"
      #     727632011
      #   elsif self.property(:gender) == ""
          
      # elsif 

      # elsif 

      # elsif 
      ""        
    end

    def amazon_department
      self.first_property(:category)
    end

    def amazon_description
      self.description
    end

    def amazon_manufacturer
      ""
    end

    def amazon_mfr_part_number
      ""
    end

    def amazon_shipping_cost
      if !master.fulfillment_cost.nil? && master.fulfillment_cost > 0
        master.fulfillment_cost.to_f
      else
        ""
      end
    end

    def amazon_item_package_quantity
      count = self.first_property(:count)
      if count.kind_of?(Array)
        count = count[0]
      end
      if count.nil?
        1
      else
        Integer(count)
      end
    end

    def amazon_size
      self.first_property(:size)
    end

    def amazon_color
      self.first_property(:color)
    end

    def amazon_gender
      self.first_property(:gender)
    end

    def amazon_material
      self.first_property(:material)
    end

    def amazon_occasion
      if self.taxons.present? && self.taxons.first.present? && self.taxons.first.name.present?
        self.taxons.first.name
      else
        ""
      end      
    end

    def amazon_sku_bid
      # if self.master.stock_items.first.count_on_hand <= 0
      #   0.0
      # else
      #   ""
      # end
      ""
    end

    def ebay_unique_merchant_sku
      self.id
    end

    def ebay_product_name
      self.name
    end

    def ebay_product_url
      "#{self.url}?utm_source=ebaycn&utm_medium=cpc&utm_campaign=ebay-product-ads"
    end

    def ebay_image_url
      self.max_image_url
    end

    def ebay_current_price
      self.price.to_s
    end

    def ebay_stock_availability
      self.master.stock_items.sum(:count_on_hand) > 0 ? 'In Stock' : 'Out of Stock'
    end

    def ebay_condition
      "New"
    end

    def ebay_upc
      self.upc
    end

    def ebay_shipping_rate
      self.master.fulfillment_cost
    end

    def ebay_original_price
      self.msrp
    end

    def ebay_brand
      self.first_property(:brand)
    end

    def ebay_product_description
      self.description
    end

    def ebay_product_type
      type = ""
      if self.first_property(:type)
        type = self.first_property(:type)
      elsif self.first_property(:group)
        type = self.first_property(:group)
      elsif self.first_property(:category)
        type = self.first_property(:category)
      end
      if type.kind_of?(Array)
        type = type[0].to_s
      end
      type
    end

    def ebay_category
      types = []
      if self.first_property(:category)
        types << self.first_property(:category)
      end
      if self.first_property(:group)
        types << self.first_property(:group)
      end
      if self.first_property(:type)
        types << self.first_property(:type)
      end
      types.join(' > ')
    end

    def bing_mpid
      self.id
    end

    def bing_title
      self.name
    end

    def bing_brand
      self.first_property(:brand)
    end

    def bing_producturl
      "#{self.url}?utm_source=bing&utm_medium=cpc&utm_campaign=bing-product-ads"
    end

    def bing_price
      self.price.to_s
    end

    def bing_description
      self.description
    end

    def bing_imageurl
      ebay_image_url
    end

    def bing_upc
      self.upc
    end

    def bing_sku
      self.sku
    end

    def bing_shipping
      ebay_shipping_rate
    end

    def bing_condition
      "New"
    end

    def bing_producttype
      ebay_category
    end

    def bing_availability
      ebay_stock_availability
    end
  end
end