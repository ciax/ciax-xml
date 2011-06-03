#!/usr/bin/ruby
require 'libverbose'
require 'librerange'

# Parameter must be numerical
class Param < Hash
  def initialize(db,al=nil) # command,alias
    @v=Verbose.new("PARAM",5)
    @db=db
    if al
      @label=al[:label]
      @alias=al[:ref]
     else
      @label=db[:label]
      @alias={}
      @label.each{|k,v|
        @alias[k]=k
      }
    end
  end

  def setpar(stm)
    @v.msg{"SetPar: #{stm}"}
    @stm=stm.dup
    self[:id]=@alias[stm.first]
    self
  end

  def check_id
    id=@stm.first
    @v.list(@label,"== Command List==") unless @label.key?(id)
    id=self[:id]
    @db.each{|k,v|
      self[k]=v[id]
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
        i > 0 ? validate(range,@stm[i]) : self[:id]
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
