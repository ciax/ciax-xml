#!/usr/bin/ruby
require 'libverbose'
require 'librerange'

# Parameter must be numerical
class Param < Hash
  def initialize
    @stm=[]
    @v=Verbose.new("Parameter")
  end

  def setpar(stm)
    @stm=stm
  end

  def subst(str)
    return str unless /\$[\d]+/ === str
    @v.msg(1){"Substitute from [#{str}]"}
    begin
      id=@stm[0]
      str=str.gsub(/\$([\d]+)/){
        i=$1.to_i
        @v.msg{"Param No. [#{i}]"}
        i > 0 ? validate(self[id][i-1],@stm[i]) : id
      }
      @v.err("Nil string") if str == ''
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
