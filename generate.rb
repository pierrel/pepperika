require 'yaml'
require 'rx'

require './lib/parser'
require './lib/utils'
require './lib/transfer'
require './lib/formatter'

# get the cookie from the cookie file
cookie = File.open('cookie.txt', 'r') {|file| file.read}.strip

# grab the data and write it to a hash
transfer = Transfer.new(cookie)

Rx::Observable.of_enumerable(transfer.pages).take(50).map do |url|
  # get the html for each url
  sleep 0.01
  puts "doing #{url}"
  [url, transfer.page(url)]
end.map do |url, html|
  # parse the html
  parser = Parser.new(html)

  attrs = {
    'name' => parser.name,
    'servings' => parser.servings,
    'ingredients' => parser.ingredients,
    'directions' => parser.directions
  }

  img = parser.photo_url
  attrs['photo_url'] = img

  src = parser.source_url
  attrs['source_url'] = src if src

  attrs
end.map do |first_pass|
  # convert url to image
  #  first copy everything besides the url
  attrs = {}
  first_pass.each_pair do |key, val|
    attrs[key] = val unless key == 'photo_url'
  end

  #  then download the image
  img = first_pass['photo_url']
  attrs['photo'] = Utils.url_to_string(img) if img

  attrs
end.map do |second_pass|
  Formatter.formatted(second_pass)
end.reduce([]) do |recipes, recipe|
  recipes + [recipe]
end.subscribe(
  lambda do |final_arr|
    File.open('recipes.yml', 'w') do |file|
      file.write(final_arr.to_yaml)
    end
  end,
  lambda do |error|
    puts "error #{error}"
  end,
  lambda do
    puts "done"
  end
)
