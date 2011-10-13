#!/usr/bin/ruby
require "libmsg"
require "liburi"
require "libelapse"

class Rview < Uri
  attr_reader :last
  def initialize(id=nil,host=nil)
    @v=Msg::Ver.new('view',6)
    super('view',id,host)
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
    else
      load
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
