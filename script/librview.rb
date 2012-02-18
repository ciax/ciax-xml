#!/usr/bin/ruby
require "libmsg"
require "libiofile"
require "libelapse"

class Rview < IoFile
  def initialize(id=nil,host=nil)
    super('view',id,host)
    stat=self['stat']||={}
    @last={}
    def stat.to_s
      Msg.view_struct(self,'stat')
    end
  end

  def get(id)
    @v.msg{"getting status of #{id}"}
    case id
    when 'elapse'
      @elapse
    else
      self['stat'][id]
    end
  end

  def set(hash) #For Watch test
    self['stat'].update(hash)
    self['stat']['time']=Msg.now
    @updlist.upd
    self
  end

  def change?(id)
    @v.msg{"Compare(#{id}) current=[#{self['stat'][id]}] vs last=[#{@last[id]}]"}
    self['stat'][id] != @last[id]
  end

  def update?
    change?('time')
  end

  def refresh
    @v.msg{"Status Updated"}
    @last.update(self['stat'])
  end
end

if __FILE__ == $0
  Msg.usage "[id] (host)" if ARGV.size < 1
  puts Rview.new(*ARGV).load
end
