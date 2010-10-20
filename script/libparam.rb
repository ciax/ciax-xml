#!/usr/bin/ruby
require 'libverbose'
class Param < Array
  def initialize
    @v=Verbose.new("Parameter")
  end

  def setpar(stm)
    replace(stm)
  end

  def sub_par(str)
    return str unless /\$[\d]+/ === str
    @v.msg(1){"Substitute from [#{str}]"}
    begin
      # Sub $key => self[key]
      str=str.gsub(/\$([\d]+)/){ self[$1.to_i] }
      raise if str == ''
      str
    ensure
      @v.msg(-1){"Substitute to [#{str}]"}
    end
  end
end
