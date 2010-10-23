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
    if @odb['command']
      @session=@odb.select_id('command',stm[0])
      a=@session.attributes
      @v.msg{"Exec(ODB):#{a['label']}"}
      stm[1..-1].unshift(a['ref'])
    else
      stm
    end
  end
end
