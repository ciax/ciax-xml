#!/usr/bin/ruby
require "libxmldoc"
require "libmodxml"
require "libverbose"

class ObjCmd
  include ModXml

  def initialize(obj)
    @odb=XmlDoc.new('odb',obj)
  rescue RuntimeError
    abort $!.to_s
  else
    @v=Verbose.new("odb/#{obj}".upcase)
  end
  
  public
  def alias(stm)
    par=stm.dup
    if @odb['command']
      @session=@odb.select_id('command',par.shift)
      a=@session.attributes
      @v.msg{"Exec(ODB):#{a['label']}"}
      [a['ref'],*par]
    else
      par
    end
  end
end
