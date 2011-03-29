#!/usr/bin/ruby
require "libxmldoc"
require "libverbose"

class Alias
  def initialize(obj)
    @odb=XmlDoc.new('odb',obj)
  rescue RuntimeError
  else
    @v=Verbose.new("alias/#{obj}".upcase)
  end
  
  public
  def alias(stm)
    raise unless Array === stm
    if @odb && @odb['command']
      @session=@odb.select_id('command',stm[0])
      @v.msg{"Before:#{stm}(#{@session['label']})"}
      stm[1..-1].unshift(@session['ref'])
      @v.msg{"After:#{stm}"}
    end
    stm
  end
end
