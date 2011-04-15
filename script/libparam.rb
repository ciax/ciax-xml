#!/usr/bin/ruby
require 'libverbose'
require 'librerange'

class Param < Array
  def initialize
    @v=Verbose.new("Parameter")
  end

  def setpar(e1,stm)
    if e1['parameters']
      i=0
      e1['parameters'].each{|e2| #//par
        validate(e2,stm[i+=1])
      }
    end
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

  def validate(e,str)
    label=e['label']
    str || @v.err("Validate: Too Few Parameters(#{label})")
    @v.msg{"Validate: String for [#{str}]"}
    case e['validate']
    when 'regexp'
      @v.msg{"Validate: Match? [#{e['val']}]"}
      return(str) if /^#{e['val']}$/ === str
    when 'range'
      e['val'].split(',').each{|r|
        @v.msg{"Validate: Match? [#{r}]"}
        return(str) if ReRange.new(r) == str
      }
    else
      return(str)
    end
    @v.err("Validate: Parameter invalid(#{label})")
  end
end
