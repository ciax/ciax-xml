#!/usr/bin/ruby
require "libmsg"
require "libiofile"
require "libelapse"

class Stat < IoFile
  def initialize(id=nil,host=nil)
    super('view',id,host)
    val=self['val']||={}
    @last={}
    def val.to_s
      Msg.view_struct(self,'val')
    end
  end

  def get(id)
    @v.msg{"getting status of #{id}"}
    case id
    when 'elapse'
      @elapse
    else
      self['val'][id]
    end
  end

  def set(hash) #For Watch test
    self['val'].update(hash)
    self['val']['time']=Msg.now
    self
  end

  def change?(id)
    @v.msg{"Compare(#{id}) current=[#{self['val'][id]}] vs last=[#{@last[id]}]"}
    self['val'][id] != @last[id]
  end

  def update?
    change?('time')
  end

  def refresh
    @v.msg{"Status Updated"}
    @last.update(self['val'])
  end
end

if __FILE__ == $0
  Msg.usage "[id] (host)" if ARGV.size < 1
  puts Stat.new(*ARGV).load
end
