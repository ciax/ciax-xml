#!/usr/bin/ruby
require "libmsg"
require "libexhash"
require "open-uri"
require "time"

class UriView < ExHash
  def initialize(id,host=nil)
    base="/json/view_#{id}.json"
    if host
      @uri="http://"+host+base
    else
      @uri=VarDir+base
    end
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
      update_j(f.read)
    } rescue
    self
  end
end

if __FILE__ == $0
  abort "Usage: #{$0} [id] (host)" if ARGV.size < 1
  puts UriView.new(*ARGV)
end
