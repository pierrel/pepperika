require 'restclient'

# Knows how to talk to the website

class Transfer
  def initialize(cookie)
    @cookie = {'.ASPXAUTH' => cookie}
  end

  def page(url)
    RestClient.get(url, cookies: cookie)
  end

  private
  def cookie
    @cookie
  end
end
