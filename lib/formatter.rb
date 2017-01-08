# Knows how to format the parts of the yml

module Formatter
  def self.formatted(hash)
    # copy it
    attrs = {}
    hash.each_pair{|key, value| attrs[key] = value}

    # make some changes
    attrs['ingredients'] = attrs['ingredients'].join("\n"),
    attrs['directions'] = attrs['directions'].each_with_index.map{|str, i|
      "#{i+1}. #{str}"
    }.join("\n\n")
    
    attrs
  end
end
