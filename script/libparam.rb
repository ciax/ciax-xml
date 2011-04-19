#!/usr/bin/ruby
require 'libverbose'
require 'librerange'

class Param < Hash
  def initialize
    @stm=[]
    @v=Verbose.new("Parameter")
  end

  def setpar(stm)
    i=0
    id=stm[i]
    self[id].each{|par|
      validate(par,stm[i+=1])
    } if key?(id)
    @stm=stm
  end

  def subst(str)
    return str unless /\$[\d]+/ === str
    @v.msg(1){"Substitute from [#{str}]"}
    begin
      # Sub $key => self[key]
      str=str.gsub(/\$([\d]+)/){ @stm[$1.to_i] }
      raise if str == ''
      str
    ensure
      @v.msg(-1){"Substitute to [#{str}]"}
    end
  end

  def validate(par,str)
    label=par['label']
    str || @v.err("Validate: Too Few Parameters(#{label})")
    @v.msg{"Validate: String for [#{str}]"}
    case par['validate']
    when 'regexp'
      @v.msg{"Validate: Match? [#{par['val']}]"}
      return(str) if /^#{par['val']}$/ === str
    when 'range'
      par['val'].split(',').each{|r|
        @v.msg{"Validate: Match? [#{r}]"}
        return(str) if ReRange.new(r) == str
      }
    else
      return(str)
    end
    @v.err("Validate: Parameter invalid(#{label})")
  end
end
