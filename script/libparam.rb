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

  def subst(h) # h={ val,range,format }
    str=h['val']
    return str unless /\$[\d]+/ === str
    @v.msg(1){"Substitute from [#{str}]"}
    begin
      id=@stm[0]
      str=str.gsub(/\$([\d]+)/){
        i=$1.to_i
        @v.msg{"Param No. [#{i}]"}
        i > 0 ? validate(h,@stm[i]) : id
      }
      @v.err("Nil string") if str == ''
      str=h['format'] % eval(str) if h['format']
      str
    ensure
      @v.msg(-1){"Substitute to [#{str}]"}
    end
  end

  private
  def validate(par,str)
    str || @v.err("Validate: Too Few Parameters")
    r=par['range']
    return(str) unless r
    label=r.tr(':','-')
    @v.msg{"Validate: [#{str}] Match? [#{r}]"}
    return(str) if ReRange.new(r) == str
    @v.err("Validate: Parameter invalid(#{label})")
  end
end
