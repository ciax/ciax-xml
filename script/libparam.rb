#!/usr/bin/ruby
require 'libmsg'
require 'librerange'

class Param < Hash
  attr_reader :list
  def initialize(db) # command db
    @v=Msg::Ver.new("param",2)
    @db=Msg.type?(db,Hash)
    label=db[:label].reject{|k,v|
      /true|1/ === db[:hidden][k] if db.key?(:hidden)
    }
    @list=Msg::List.new("== Command List==").add(label)
  end

  def set(cmdary)
    id=cmdary.first
    unless @db[:select].key?(id)
      raise SelectCMD,("No such CMD [#{id}]\n"+@list.to_s)
    end
    @v.msg{"SetPar: #{cmdary}"}
    @cmdary=cmdary.dup
    self[:command]=id
    self[:cid]=cmdary.join(':')
    @db.each{|k,v|
      self[k]=v[id]
    }
    if par=self[:parameter]
      unless par.size < cmdary.size
        Msg.err("Parameter shortage",@list[id])
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

  private
  def validate(str,va=nil)
    if va
      Msg.err("No Parameter") unless str
      num=eval(str)
      @v.msg{"Validate: [#{num}] Match? [#{va}]"}
      va.split(',').each{|r|
        break if ReRange.new(r) == num
      } && Msg.err(" Parameter invalid (#{num}) for [#{va.tr(':','-')}]")
      str=num.to_s
    end
    str
  end
end
