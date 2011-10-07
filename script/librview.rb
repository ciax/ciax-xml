#!/usr/bin/ruby
require "libmsg"
require "libexhash"
require "libelapse"

class Rview < ExHash
  def initialize(id=nil,host=nil)
    if id
      base="/json/view_#{id}.json"
      if host
        require "open-uri"
        @uri="http://"+host+base
      else
        @uri=VarDir+base
      end
    end
    upd
    self['stat']||={}
    self['stat']['elapse']=Elapse.new(self['stat'])
  end

  def upd
    if @uri
      open(@uri){|f| update_j(f.read) }
    else
      update_j(gets)
    end
    self
  end
end

if __FILE__ == $0
  abort "Usage: #{$0} [id] (host)" if ARGV.size < 1
  puts Rview.new(*ARGV)
end
