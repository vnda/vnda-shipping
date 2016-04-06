class MapRule < ActiveRecord::Base

  belongs_to :shipping_method
  has_one :shop, through: :shipping_method
  has_and_belongs_to_many :periods

  validates :name, :price, :deadline, presence: true  

  def self.build_from(xml_doc)
    xml_doc.css('Document Folder Placemark').collect do |placemark|
      MapRule.new(
        name: placemark.css('name').text, 
        price: nil,
        deadline: nil,
        coordinates: placemark.css('Polygon coordinates').text
      )
    end
  end
end
