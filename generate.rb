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

def all_hashes(cookie)
  transfer = Transfer.new(cookie)
  
  transfer.pages.take(1).map do |url|
    sleep 0.01
    puts "doing #{url}"
    page = transfer.page(url)

    page_to_hash(page)
  end
end

def write_all_hashes(cookie)
  File.open("recipes.yml", "w") do |file|
    file.write(all_hashes(cookie).to_yaml)
  end
end

write_all_hashes(cookie)
