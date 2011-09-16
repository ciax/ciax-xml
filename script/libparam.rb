#!/usr/bin/ruby
require 'libmsg'
require 'libmodconv'

class Param < Hash
  include ModConv
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
    if par=self[:parameter]
      unless par.size < cmdary.size
        Msg.err("Parameter shortage","#{id} : #{@label[id]}")
      end
      ary=cmdary[1..-1]
      par.each{|r|
        validate(ary.shift,r)
      }
    end
    self
  end

  def subst(str) # par={ val,range,format } or String
    return str unless /\$[\d]+/ === str
    @v.msg(1){"Substitute from [#{str}]"}
    begin
      str=str.gsub(/\$([\d]+)/){
        i=$1.to_i
        @v.msg{"Param No.#{i} = [#{@cmdary[i]}]"}
        @cmdary[i] || Msg.err(" No substitute data ($#{i})")
      }
      Msg.err("Nil string") if str == ''
      str
    ensure
      @v.msg(-1){"Substitute to [#{str}]"}
    end
  end
end
