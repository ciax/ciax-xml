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
    def @stat.to_s
      Msg.view_struct(self,'stat')
    end
  end

  def stat(id=nil)
    case id
    when nil
      @stat
    when 'elapse'
      @elapse
    else
      @stat[id]
    end
  end

  def set(hash) #For Watch test
    @stat.update(hash)
    @stat['time']=Msg.now
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
    @v.msg{"Status Updated"}
    @last.update(@stat)
  end
end

if __FILE__ == $0
  Msg.usage "[id] (host)" if ARGV.size < 1
  puts Rview.new(*ARGV).load
end
