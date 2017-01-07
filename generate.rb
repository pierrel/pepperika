require 'yaml'
require 'open-uri'
require 'base64'

require './lib/parser'
require './lib/utils'
require './lib/transfer'

cookie = File.open('cookie.txt', 'r') {|file| file.read}.strip

def urls()
  url_arr = []
  text=File.open('urls.txt').read
  text.gsub!(/\r\n?/, "\n")
  text.each_line do |line|
    url_arr << line.strip
  end

  url_arr
end

def page_to_hash(html)
  parser = Parser.new(html)

  attrs = {
    'name' => parser.name,
    'servings' => parser.servings,
    'ingredients' => parser.ingredients,
    'directions' => parser.directions,
  }

  img = parser.photo_url
  attrs['photo'] = Utils.url_to_string(img) if img

  src = parser.source_url
  attrs['source_url'] = src if src

  attrs
end

def all_hashes(cookie)
  urls.map do |url|
    sleep 0.01
    puts "doing #{url}"
    page = Transfer.new(cookie).page("http://www.pepperplate.com/recipes/#{url}")

    page_to_hash(page)
  end
end

def write_all_hashes(cookie)
  File.open("all_recipes.yml", "w") do |file|
    file.write(all_hashes(cookie).to_yaml)
  end
end

write_all_hashes(cookie)




def convert_yaml()
  data = YAML.load_file('all_recipes.yml')
  data.each do |recipe|
    sleep 0.1
    puts "doing #{recipe['name']}"
    if recipe.has_key?('image_url')
      recipe['photo'] = Base64.encode64(open(recipe['image_url']) {|io| io.read})
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
