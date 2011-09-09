#!/usr/bin/ruby
require "json"
require "open-uri"

class UriView
  def initialize(id,host=nil)
    host||='localhost'
    @uri="http://#{host}/json/status_#{id}.json"
  end

  def get
    view={}
    open(@uri){|f|
      view=JSON.load(f.read)
    }
    view
  end
end
