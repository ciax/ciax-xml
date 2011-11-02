#!/usr/bin/ruby
require "libclient"
require "librview"
require "libparam"

class AppCl < Client
  attr_reader :view
  def initialize(adb,host=nil)
    id=adb['id']
    host||=adb['host']
    super(id,adb['port'],host)
    @view=Rview.new(id,host).load
    @par=Param.new(adb[:command])
  end

  def upd(cmd)
    @par.set(cmd) if super(cmd).message
    @view.load
    self
  end
end
