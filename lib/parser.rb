require 'nokogiri'

# Knows how to parse html from the website

class Parser
  def initialize(html)
    @doc = Nokogiri::HTML(html)
  end

  def name
    doc.css('.recipedet h2>span').text
  end

  def ingredients
    doc.css('ul.inggroups ul.inggroupitems li.item span.content').map{|ing|
      quantity = ing.css('.ingquantity').text
      ingredient = ing.children.last.text.gsub("\r|\n", '').strip
      
      if quantity.empty?
        ingredient
      else
        "#{quantity} #{ingredient}"
      end
    }
  end

  def directions
    doc.css('.dirgroups .dirgroupitems li span').map{|dir| dir.text}
  end

  def servings
    doc.css('#cphMiddle_cphMain_lblYield').text
  end

  def source_url
    source_el = doc.css('#cphMiddle_cphSidebar_hlOriginalRecipe')
    if source_el.empty?
      nil
    else
      source_el.attribute('href').value
    end
  end

  def photo_url
    image = doc.css ".recipedet .imagecontainer img"
    if image.empty?
      nil
    else
      image.attribute('src').value
    end
  end

  def recipe_links
    doc.css('.item a').map do |link|
      link.attribute('href').value
    end
  end

  private
  def doc
    @doc
  end
end
