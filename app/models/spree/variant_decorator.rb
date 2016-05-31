 Spree::Variant.class_eval do
  has_many :product_ads
  after_create :create_product_ads

  def create_product_ads
    Spree::ProductAdChannel.all.each do |channel|    
      if product_ads.select{|ad|ad.channel == channel}.empty?
        next unless self.is_master
        product_ads.create(
          :channel => channel, 
          :state => "enabled", 
          :max_cpc => (self.max_cpc || channel.default_max_cpc)
        )
      end
    end
  end
end