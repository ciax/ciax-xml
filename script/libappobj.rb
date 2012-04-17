#!/usr/bin/ruby
require "libinteract"
require "libstat"
class AppObj < Interact
  def initialize(adb)
    @adb=Msg.type?(adb,AppDb)
    super(Command.new(adb[:command]))
    @prompt['id']=adb['id']
    @port=adb['port'].to_i
    @stat=Stat.new
    @watch=Watch::Stat.new
    @ic.add('set'=>"[key=val] ..")
    @ic.add('flush'=>"Flush Status")
    def @prompt.to_s
      str=''
      str << self['id']
      str << '@' if self['auto']
      str << '&' if self['watch']
      str << '*' if self['isu']
      str << (self['buff'] ? '>' : 'X')
      str
    end
  end

  def to_s
    @stat.to_s
  end
end
