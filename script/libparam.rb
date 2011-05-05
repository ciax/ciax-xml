#!/usr/bin/ruby
require 'libverbose'
require 'librerange'

# Parameter must be numerical
class Param
  def initialize(list)
    @list=list
    @stm=[]
    @v=Verbose.new("PARAM",4)
  end

  def setpar(stm)
    @v.msg{"SetPar: #{stm}"}
    @stm=stm.dup
    @list[stm.first] || raise(SelectID,@v.list(@list,"== Command List=="))
  end

  def subst(str,range=nil) # par={ val,range,format } or String
    return str unless /\$[\d]+/ === str
    @v.msg(1){"Substitute from [#{str}]"}
    begin
      id=@stm[0]
      str=str.gsub(/\$([\d]+)/){
        i=$1.to_i
        @v.msg{"Param No.#{i} = [#{@stm[i]}]"}
        i > 0 ? validate(range,@stm[i]) : id
      }
      @v.err("Nil string") if str == ''
      str
    ensure
      @v.msg(-1){"Substitute to [#{str}]"}
    end
  end

  def [](key)
    @list[@stm.first][key]
  end

  private
  def validate(range,str)
    str || @v.err(" Short of Parameters")
    return(str) unless range
    label=range.tr(':','-')
    @v.msg{"Validate: [#{str}] Match? [#{range}]"}
    range.split(',').each{|r|
      return(str) if ReRange.new(r) == str
    }
    @v.err(" Parameter invalid(#{label})")
  end
end
