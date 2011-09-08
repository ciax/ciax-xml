#!/usr/bin/ruby
require 'libverbose'
require 'librerange'

# Parameter must be numerical
class Param < Hash
  def initialize(db) # command db
    @v=Verbose.new("PARAM",5)
    @db=db
    @label=db[:label]
    @v.add("== Command List==").add(@label)
  end

  def setpar(cmd)
    @v.msg{"SetPar: #{cmd}"}
    @cmd=cmd.dup
    self[:id]=cmd.first
    self
  end

  def check_id
    id=@cmd.first
    @v.list unless @label.key?(id)
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
        @v.msg{"Param No.#{i} = [#{@cmd[i]}]"}
        i > 0 ? validate(range,@cmd[i]) : self[:id]
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
