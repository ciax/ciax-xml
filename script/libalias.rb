#!/usr/bin/ruby
require "libverbose"
require "libobjdb"

class Alias
  def initialize(odb)
    @v=Verbose.new("alias/#{odb['id']}".upcase,6)
    @odb=odb[:command]||return
    @v.add("=== Command List ===")
    @v.add(@odb[:label])
  end

  def alias(str)
    return str unless @odb
    @v.list if str.empty?
    @v.msg{"Command:#{str}"}
    rel=str.dup
    @odb[:alias].each{|k,v|
      rel.sub!(/^#{k}\b/,v) && break
    } && @v.list
    @v.msg{"Subst:#{str}->#{rel}"}
    rel
  end
end
