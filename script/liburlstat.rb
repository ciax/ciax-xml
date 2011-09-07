#!/usr/bin/ruby
require "json"
require "open-uri"

class UrlStat
  def initialize(id,host=nil)
    host||='localhost'
    @url="http://#{host}/json/status_#{id}.json"
  end

  def get
    stat={}
    open(@url){|f|
      stat=JSON.load(f.read)
    }
    stat
  end
end
