#!/usr/bin/ruby
require 'libverbose'
require 'librerange'

class Param0 < Array

  def initialize
    @v=Verbose.new("Parameter")
  end

  def setpar(e0,stm)
    e0.each {|e1|
      case e1.name
      when 'parameters'
        i=0
        e1.each{|e2| #//par
          validate(e2,stm[i+=1])
        }
        break
      end
    }
    replace(stm)
  end

  def subst(str)
    return str unless /\$[\d]+/ === str
    @v.msg(1){"Substitute from [#{str}]"}
    begin
      # Sub $key => self[key]
      conv=str.gsub(/\$([\d]+)/){ self[$1.to_i] }
      raise "Empty Str by Subst Param [#{str}]" if conv == ''
      conv
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
      @v.msg{"Validate: Match? [#{e.text}]"}
      return(str) if /^#{e.text}$/ === str
    when 'range'
      e.text.split(',').each{|r|
        @v.msg{"Validate: Match? [#{r}]"}
        return(str) if ReRange.new(r) == str
      }
    else
      return(str)
    end
    @v.err("Validate: Parameter invalid(#{label})")
  end
end
