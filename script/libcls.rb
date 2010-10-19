#!/usr/bin/ruby
require "libxmldoc"
require "libvar"

class Cls < Var
  attr_reader :device

  def initialize(cls)
    @cdb=XmlDoc.new('cdb',cls)
  rescue RuntimeError
    abort $!.to_s
  else
    @device=@cdb['device']
  end
end
