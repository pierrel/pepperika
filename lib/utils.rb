module Utils
  class<<self
    def url_to_string(image_url)
      Base64.encode64(open(image_url) {|io| io.read})
    end
  end
end
