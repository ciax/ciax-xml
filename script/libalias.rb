#!/usr/bin/ruby
require "libxmldoc"
require "libverbose"

class Alias
  def initialize(obj)
    @odb=XmlDoc.new('odb',obj)
  rescue RuntimeError
  else
    @v=Verbose.new("odb/#{obj}".upcase)
  end
  
  public
  def alias(stm)
    if @odb && @odb['command']
      @session=@odb.select_id('command',stm[0])
      @v.msg{"Exec(ODB):#{@session['label']}"}
      stm[1..-1].unshift(@session['ref'])
    else
      stm
    end
  end
end
