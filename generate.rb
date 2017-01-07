require 'yaml'
require 'open-uri'
require 'base64'

require './lib/parser'
require './lib/utils'
require './lib/transfer'

def page_to_hash(html)
  parser = Parser.new(html)

  attrs = {
    'name' => parser.name,
    'servings' => parser.servings,
    'ingredients' => parser.ingredients.join("\n"),
    'directions' => parser.directions.each_with_index.map{|str, i|
      "#{i+1}. #{str}"
    }.join("\n\n")
  }

  img = parser.photo_url
  attrs['photo'] = Utils.url_to_string(img) if img

  src = parser.source_url
  attrs['source_url'] = src if src

  attrs
end

# get the cookie from the cookie file
cookie = File.open('cookie.txt', 'r') {|file| file.read}.strip

# grab the data and write it to a hash
transfer = Transfer.new(cookie)
  
data_hash = transfer.pages.map do |url|
  sleep 0.01
  puts "doing #{url}"
  page = transfer.page(url)
  
  page_to_hash(page)
end

# open the yml file and write
File.open("recipes.yml", "w") do |file|
  file.write(data_hash.to_yaml)
end
