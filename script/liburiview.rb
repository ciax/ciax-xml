#!/usr/bin/ruby
require "libmsg"
require "json"
require "open-uri"

class UriView < Hash
  def initialize(id,host=nil)
    host||='localhost'
    @uri="http://#{host}/json/status_#{id}.json"
    upd
  end

  def upd
    open(@uri){|f|
      replace(JSON.load(f.read))
    } rescue
    self
  end
end

if __FILE__ == $0
  abort "Usage: #{$0} [id] (host)" if ARGV.size < 1
  puts UriView.new(*ARGV).upd
end
