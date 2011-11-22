#!/usr/bin/ruby
require "libfrmcl"
require "libfrmsv"

class FrmInt
  attr_reader :field,:commands,:prompt
  def initialize(fdb,par)
    case par
    when Array
      @int=FrmSv.new(fdb,par)
    else
      @int=FrmCl.new(fdb,par)
    end
    @prompt=fdb['id']+'>'
    @commands=@int.commands
    @field=@int.field
  end

  def exe(cmd)
    @int.exe(cmd)
  end

  def to_s
    @int.to_s
  end
end
