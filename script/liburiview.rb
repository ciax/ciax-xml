#!/usr/bin/ruby
require "libmsg"
require "json"
require "open-uri"
require "time"

class UriView < ExHash
  def initialize(id,host=nil)
    host||='localhost'
    @uri="http://#{host}/json/view_#{id}.json"
    upd
  end

  def latest?
    now=Time.parse(self['time'])
    return if @last == now
    @last=now
    self
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
  puts UriView.new(*ARGV)
end
