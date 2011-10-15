#!/usr/bin/ruby
require "libclient"
require "librview"
require "libprint"
require "libparam"

class AppCl
  attr_reader :view,:prompt
  def initialize(adb,host)
    id=adb['id']
    @cli=Client.new(id,adb['port'],host)
    @prompt=@cli.prompt
    @view=Rview.new(id,host).load
    @prt=Print.new(adb[:status],@view)
    @par=Param.new(adb[:command])
  end

  def upd(cmd)
    @par.set(cmd) if @cli.upd(cmd).message
    @view.load
    self
  end

  def to_s
    @cli.message||@prt.to_s
  end
end
