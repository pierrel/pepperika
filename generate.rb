require 'restclient'
require 'nokogiri'
require 'yaml'
require 'open-uri'
require 'base64'

cookie = {
  '.ASPXAUTH' => File.open('cookie.txt', 'r') {|file| file.read}.strip
}

def urls()
  url_arr = []
  text=File.open('urls.txt').read
  text.gsub!(/\r\n?/, "\n")
  text.each_line do |line|
    url_arr << line.strip
  end

  url_arr
end

def name(doc)
   doc.css('.recipedet h2>span').text
end

def ingredients(doc)
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

def directions(doc)
  doc.css('.dirgroups .dirgroupitems li span').map{|dir| dir.text}
end

def servings(doc)
  doc.css('#cphMiddle_cphMain_lblYield').text
end

def recipe_source(doc)
  source_el = doc.css('#cphMiddle_cphSidebar_hlOriginalRecipe')
  if source_el.empty?
    nil
  else
    source_el.attribute('href').value
  end
end

def image_url(doc)
  image = doc.css ".recipedet .imagecontainer img"
  if image.empty?
    nil
  else
    image.attribute('src').value
  end
end

def url_to_string(image_url)
  Base64.encode64(open(image_url) {|io| io.read})
end

def recipe_to_hash(url, cookie)
  resp = RestClient.get(url, cookies: cookie)
  doc = Nokogiri::HTML(resp)

  attrs = {
p    'name' => name(doc),
    'servings' => servings(doc),
    'ingredients' => ingredients(doc),
    'directions' => directions(doc),
  }

  img = image_url(doc)
  attrs['photo'] = url_to_string(img) if img

  src = recipe_source(doc)
  attrs['source_url'] = src if src

  attrs
end

def all_hashes(cookie)
  urls.map do |url|
    sleep 0.01
    puts "doing #{url}"

    recipe_to_hash("http://www.pepperplate.com/recipes/#{url}",
                   cookie)
  end
end

def write_all_hashes(cookie)
  File.open("all_recipes.yml", "w") do |file|
    file.write(all_hashes(cookie).to_yaml)
  end
end

def convert_yaml()
  data = YAML.load_file('all_recipes.yml')
  data.each do |recipe|
    sleep 0.1
    puts "doing #{recipe['name']}"
    if recipe.has_key?('image_url')
      recipe['photo'] = Base64.encode64(open(recipe['image_url']) {|io| io.read})
      recipe.delete('image_url')
    end

    if recipe.has_key?('source')
      recipe['source_url'] = recipe['source']
      recipe.delete('source')
    end

    recipe['directions'] = recipe['directions'].each_with_index.map{|str, i|
      "#{i+1}. #{str}"
    }.join("\n\n")

    recipe.each_pair do |key, value|
      recipe[key] = value.join("\n") if value.is_a?(Array)
    end
  end

  
  File.open("complete_recipes.yml", "w") do |file|
    file.write(data.to_yaml)
  end
end

convert_yaml



