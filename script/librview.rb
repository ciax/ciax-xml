#!/usr/bin/ruby
require "libmsg"
require "libexhash"
require "libelapse"

class Rview < ExHash
  attr_reader :last
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
    @stat=self['stat']=ExHash.new
    @last=ExHash.new
    @stat['elapse']=Elapse.new(@stat)
  end

  def change?(id)
    @v.msg{"Compare(#{id}) current=[#{@stat[id]}] vs last=[#{@last[id]}]"}
    @stat[id] != @last[id]
  end

  def upd(stat=nil)
    if stat
      @stat.deep_update(stat)
    elsif @uri
      open(@uri){|f| update_j(f.read) }
    else
      update_j(gets)
    end
    self
  end

  def update?
    if change?('time')
      @v.msg{"Status Updated"}
      @last.deep_update(@stat)
    end
  end
end

if __FILE__ == $0
  abort "Usage: #{$0} [id] (host)" if ARGV.size < 1
  puts Rview.new(*ARGV).upd
end
