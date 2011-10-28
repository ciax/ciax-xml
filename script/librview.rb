#!/usr/bin/ruby
require "libmsg"
require "libiofile"
require "libelapse"

class Rview < IoFile
  attr_reader :last
  def initialize(id=nil,host=nil)
    super('view',id,host)
    @stat||={}
    self['stat']=@stat
    @last={}
    @elapse=Elapse.new(@stat)
  end

  def stat(id)
    id == 'elapse' ? @elapse : @stat[id]
  end

  def set(hash)
    @stat.update(hash)
    @stat['time']="%.3f" % Time.now.to_f
    self
  end

  def change?(id)
    @v.msg{"Compare(#{id}) current=[#{@stat[id]}] vs last=[#{@last[id]}]"}
    @stat[id] != @last[id]
  end

  def update?
    change?('time')
  end

  def refresh
    if update?
      @v.msg{"Status Updated"}
      @last.update(@stat)
    end
  end
end

if __FILE__ == $0
  abort "Usage: #{$0} [id] (host)" if ARGV.size < 1
  puts Rview.new(*ARGV).load
end
