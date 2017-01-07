require 'restclient'
require 'json'

require_relative './parser'

# Knows how to talk to the website

class Transfer
  ROOT = "http://www.pepperplate.com/recipes"
  PAGE_SIZE = 20
  
  def initialize(cookie)
    @cookie = cookie
  end

  def page(url)
    RestClient.get(url, cookies: cookie_hash)
  end

  def pages
    Pages.new(@cookie)
  end

  private
  def cookie_hash
    {'.ASPXAUTH' => @cookie}
  end

  class Pages
    include Enumerable

    def initialize(cookie)
      @offset = 0
      @cookie = cookie
    end

    def each(&block)
      links_run = run_through_links(&block)

      until links_run.length < PAGE_SIZE
        @offset += 1
        links_run = run_through_links(&block)
      end
    end

    def run_through_links(&block)
      urls = request_links
      urls.each{|url| block.call(url)}
      urls
    end
    
    def request_links
      resp = `curl '#{ROOT}/default.aspx/GetPageOfResults' -H 'Cookie: .ASPXAUTH=#{@cookie}' -H 'Content-Type: application/json; charset=UTF-8' -H 'Accept: application/json, text/javascript, */*; q=0.01' --data-binary '#{request_payload}' --compressed 2>/dev/null`
      html = JSON.parse(resp)['d']

      Parser.new(html).recipe_links.map{|link| "#{ROOT}/#{link}"}
    end

    def request_payload
      "{ \"pageIndex\":#{@offset}, \"pageSize\":#{PAGE_SIZE}, \"sort\":4, \"tagIds\": [], \"favoritesOnly\":0}"
    end
  end
end
