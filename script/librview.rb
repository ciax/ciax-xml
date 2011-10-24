#!/usr/bin/ruby
require "libmsg"
require "libiofile"
require "libelapse"

class Rview < IoFile
  attr_reader :last
  def initialize(id=nil,host=nil)
    super('view',id,host)
    @stat||=ExHash.new
    self['stat']=@stat
    @last=ExHash.new
    @elapse=Elapse.new(@stat)
  end

  def change?(id)
    @v.msg{"Compare(#{id}) current=[#{@stat[id]}] vs last=[#{@last[id]}]"}
    @stat[id] != @last[id]
  end

  def update?
    change?('time')
  end

  def stat(id)
    id == 'elapse' ? @elapse : @stat[id]
  end

  def refresh
    if update?
      @v.msg{"Status Updated"}
      @last.deep_update(@stat)
    end
  end
end

if __FILE__ == $0
  abort "Usage: #{$0} [id] (host)" if ARGV.size < 1
  puts Rview.new(*ARGV).load
end
