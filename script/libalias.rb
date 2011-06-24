#!/usr/bin/ruby
require "libverbose"
require "libobjdb"

class Alias
  def initialize(obj)
    @v=Verbose.new("alias/#{obj}".upcase,6)
    @odb=ObjDb.new(obj).alias
    @v.add("=== Command List ===")
    @v.add(@odb[:label])
  end
  
  public
  def alias(ssn)
    raise unless Array === ssn
    @v.msg{"Command:#{ssn}"}
    return ssn if @odb.empty?
    id=ssn.first
    if (ref=@odb[:ref][id]) && ! ssn.empty?
      @v.msg{"Before:#{ssn}(#{@odb[:label][id]})"}
      ssn=ssn[1..-1].unshift(ref)
      @v.msg{"After:#{ref}/#{ssn}"}
    else
      @v.list
    end
    ssn
  end
end
