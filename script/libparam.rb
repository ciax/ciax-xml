#!/usr/bin/ruby
require 'libmsg'
require 'libexhash'
require 'librerange'

class Param < ExHash
  attr_reader :list
  # command db (:label,:hidden,:alias,:select,:parameter)
  def initialize(db)
    @v=Msg::Ver.new("param",2)
    @db=Msg.type?(db,Hash)
    label=db[:label].reject{|k,v| /true|1/ === (db[:hidden]||{})[k] }
    @alias=db[:alias]||{}
    @alias.each{|k,v| label[k]=label.delete(v) }
    db[:select].each{|k,v| @alias[k]=k} unless db.key?(:alias)
    @list=Msg::List.new("== Command List==").add(label)
  end

  def set(cmd)
    id=Msg.type?(cmd,Array).first
    unless @alias.key?(id)
      raise SelectCMD,("No such CMD [#{id}]\n"+@list.to_s)
    end
    @v.msg{"SetPar: #{cmd}"}
    self[:id]=id
    self[:cmd]=cmd.dup
    self[:cid]=cmd.join(':')
    @db.each{|k,v|
      self[k]=v[@alias[id]] if Symbol === k
    }
    if par=self[:parameter]
      unless par.size < cmd.size
        Msg.err("Parameter shortage",@list[id])
      end
      ary=cmd[1..-1]
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
        @v.msg{"Param No.#{i} = [#{self[:cmd][i]}]"}
        self[:cmd][i] || Msg.err(" No substitute data ($#{i})")
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
      begin
        num=eval(str)
      rescue SyntaxError
        Msg.err("Parameter is not number")
      end
      @v.msg{"Validate: [#{num}] Match? [#{va}]"}
      va.split(',').each{|r|
        break if ReRange.new(r) == num
      } && Msg.err(" Parameter invalid (#{num}) for [#{va.tr(':','-')}]")
      str=num.to_s
    end
    str
  end
end
