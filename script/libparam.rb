#!/usr/bin/ruby
require 'libmsg'
require 'librerange'

class Param < Hash
  attr_reader :list
  def initialize(db) # command db
    @v=Msg::Ver.new("PARAM",5)
    @db=db
    @label=db[:label]
    @list=Msg::List.new("== Command List==").add(@label)
  end

  def set(cmdary)
    @list.exit unless @label.key?(id=cmdary.first)
    @v.msg{"SetPar: #{cmdary}"}
    @cmdary=cmdary.dup
    self[:id]=id
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
        @v.msg{"Param No.#{i} = [#{@cmdary[i]}]"}
        i > 0 ? validate(range,@cmdary[i]) : self[:id]
      }
      Msg.err("Nil string") if str == ''
      str
    ensure
      @v.msg(-1){"Substitute to [#{str}]"}
    end
  end

  private
  def validate(range,str)
    str || Msg.err(" Short of Parameters")
    return(str) unless range
    label=range.tr(':','-')
    @v.msg{"Validate: [#{str}] Match? [#{range}]"}
    range.split(',').each{|r|
      return(str) if ReRange.new(r) == str
    }
    Msg.err(" Parameter invalid(#{label})")
  end
end
