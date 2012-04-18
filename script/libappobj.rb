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
    @prompt.set({'auto' => '@','watch' => '&', 'isu' => '*','na' => 'X' })
  end

  def to_s
    @stat.to_s
  end
end
