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
  def alias(ssn)
    raise unless Array === ssn
    if @odb && @odb['command']
      @session=@odb.select_id('command',ssn[0])
      @v.msg{"Before:#{ssn}(#{@session['label']})"}
      ssn[1..-1].unshift(@session['ref'])
      @v.msg{"After:#{ssn}"}
    end
    ssn
  end
end
