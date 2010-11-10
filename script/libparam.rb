#!/usr/bin/ruby
require 'libverbose'
require 'libmodxml'

class Param < Array
  include ModXml

  def initialize
    @v=Verbose.new("Parameter")
  end

  def setpar(e0,stm)
    e0.each_element {|e1|
      case e1.name
      when 'parameters'
        i=0
        e1.each_element{|e2| #//par
          validate(e2,stm[i+=1])
        }
      end
    }
    replace(stm)
  end

  def subst(str)
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
