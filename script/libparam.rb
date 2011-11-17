#!/usr/bin/ruby
require 'libmodexh'
require 'libmsg'
require 'librerange'
require 'libmodconv'

class Param < Hash
  include ModExh
  include ModConv
  attr_reader :list
  # command db (:label,:select,:parameter)
  # frm command db (:nocache,:response)
  def initialize(db)
    @v=Msg::Ver.new("param",2)
    @db=Msg.type?(db,Hash)
    @list=Msg::Lists.new(db)
  end

  def set(cmd)
    id=Msg.type?(cmd,Array).first
    id=(@db[:alias]||={})[id]||id
    unless @db[:select].key?(id)
      @list.error("No such CMD [#{id}]")
    end
    @v.msg{"SetPar: #{cmd}"}
    self[:id]=id
    @param=cmd[1..-1]
    self[:cid]=cmd.join(':') # Used by macro
    [:label,:nocache,:response].each{|k,v|
      self[k]=@db[k][id] if @db.key?(k)
    }
    if @db.key?(:parameter) && par=@db[:parameter][id]
      unless par.size < cmd.size
        Msg.err("Parameter shortage (#{par.size})",@list[id])
      end
      par.size.times{|i|
        validate(@param[i],par[i])
      }
    end
    self[:select]=deep_subst(@db[:select][id])
    self
  end

  def subst(str) # par={ val,range,format } or String
    return str unless /\$[\d]+/ === str
    @v.msg(1){"Substitute from [#{str}]"}
    begin
      str=keyconv('0-9',str){|k|
        i=k.to_i
        @v.msg{"Param No.#{i} = [#{@param[i-1]}]"}
        @param[i-1] || Msg.err(" No substitute data ($#{i})")
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
  require "optparse"
  require 'libinsdb'
  opt=ARGV.getopts("af")
  begin
    adb=InsDb.new(ARGV.shift,true).cover_app(true)
    if opt["f"]
      puts Param.new(adb.cover_frm(true)[:cmdframe]).set(ARGV)
    else
      puts Param.new(adb[:command]).set(ARGV)
    end
  rescue
    warn "USAGE: #{$0} (-f) [id] [cmd] (par)"
    Msg.exit
  end
end
