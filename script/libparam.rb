#!/usr/bin/ruby
require 'libverbose'
require 'librerange'

# Parameter must be numerical
class Param < Hash
  def initialize(db=nil)
    @v=Verbose.new("PARAM",4)
    @db=db
  end

  def setpar(stm)
    @v.msg{"SetPar: #{stm}"}
    @stm=stm.dup
    @id=@stm.first
    self
  end

  def check_id
    return self unless @db
    @v.list(@db[:label],"== Command List==") unless @db[:label].key?(@id)
    @db.each{|k,v|
      self[k]=v[@id] if v[@id].is_a?(String)
    }
    self
  end

  def subst(str,range=nil) # par={ val,range,format } or String
    return str unless /\$[\d]+/ === str
    @v.msg(1){"Substitute from [#{str}]"}
    begin
      str=str.gsub(/\$([\d]+)/){
        i=$1.to_i
        @v.msg{"Param No.#{i} = [#{@stm[i]}]"}
        i > 0 ? validate(range,@stm[i]) : @id
      }
      @v.err("Nil string") if str == ''
      str
    ensure
      @v.msg(-1){"Substitute to [#{str}]"}
    end
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
