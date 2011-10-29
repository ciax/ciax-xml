#!/usr/bin/ruby
require 'libmsg'
require 'librerange'

class Param < Hash
  attr_reader :list
  # command db (:label,:select,:parameter)
  # app command db (:alias,:hidden)
  # frm command db (:nocache,:response)
  def initialize(db)
    @v=Msg::Ver.new("param",2)
    @db=Msg.type?(db,Hash)
    label=db[:label].reject{|k,v| /true|1/ === (db[:hidden]||{})[k] }
    @alias=db[:alias]||{}
    @alias.each{|k,v| label[k]=label.delete(v) }
    db[:select].keys.each{|k| @alias[k]=k} unless db.key?(:alias)
    @cl=Msg::List.new("== Command List==").add(label)
  end

  def set(cmd)
    id=Msg.type?(cmd,Array).first
    unless @alias.key?(id)
      @cl.error("No such CMD [#{id}]")
    end
    @v.msg{"SetPar: #{cmd}"}
    self[:id]=id
    self[:cmd]=cmd.dup
    self[:cid]=cmd.join(':')
    org=@alias[id]
    [:label,:select,:nocache,:response].each{|k,v|
      self[k]=deep_subst(@db[k][org]) if @db.key?(k)
    }
    if @db.key?(:parameter) && par=@db[:parameter][org]
      Msg.err("Parameter shortage",@cl[id]) unless par.size < cmd.size
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
  def deep_subst(data)
    case data
    when Array
      res=[]
      data.each{|v|
        res << deep_subst(v)
      }
    when Hash
      res={}
      data.each{|k,v|
        res[k]=deep_subst(v)
      }
    else
      res=subst(data)
    end
    res
  end

  def validate(str,va=nil)
    if va
      Msg.err("No Parameter") unless str
      begin
        num=eval(str)
      rescue Exception
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

if __FILE__ == $0
  require 'libinsdb'
  begin
    db=InsDb.new(ARGV.shift).cover_app
    case ARGV.shift
    when 'app'
      puts Param.new(db[:command]).set(ARGV)
    when 'frm'
      puts Param.new(db.cover_frm[:cmdframe]).set(ARGV)
    else
      raise "No type selected (app|frm)"
    end
  rescue
    warn "USAGE: #{$0} [id] [app|frm] [cmd] (par)"
    Msg.exit
  end
end
