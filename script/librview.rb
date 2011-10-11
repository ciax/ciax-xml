#!/usr/bin/ruby
require "libmsg"
require "libexhash"
require "libelapse"

class Rview < ExHash
  def initialize(id=nil,host=nil)
    @v=Msg::Ver.new('view',6)
    if id
      base="/json/view_#{id}.json"
      self['id']=id
      if host
        require "open-uri"
        @uri="http://"+host+base
      else
        @uri=VarDir+base
      end
    end
    self['stat']=ExHash.new
    @shadow={}
  end

  def stat(id)
    self['stat'][id]||@shadow[id]
  end

  def upd(stat=nil)
    if stat
      self['stat'].deep_update(stat)
    elsif @uri
      open(@uri){|f| update_j(f.read) }
    else
      update_j(gets)
    end
    @shadow['elapse']=Elapse.new(self['stat']['time'])
    self
  end
end

if __FILE__ == $0
  abort "Usage: #{$0} [id] (host)" if ARGV.size < 1
  puts Rview.new(*ARGV).upd
end
