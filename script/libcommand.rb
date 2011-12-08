#!/usr/bin/ruby
require 'libexhash'
require 'libmsg'
require 'librerange'

class Command < ExHash
  include Math
  attr_reader :list
  # command db (:label,:select,:parameter)
  # frm command db (:nocache,:response)
  def initialize(db)
    @v=Msg::Ver.new(self,2)
    @db=Msg.type?(db,Hash)
    @list=Msg::Lists.new(db)
  end

  def set(cmd)
    id=Msg.type?(cmd,Array).first
    id=(@db[:alias]||={})[id]||id
    unless @db[:select].key?(id)
      @list.error("No such CMD [#{id}]")
    end
    @v.msg{"SetCMD: #{cmd}"}
    self[:param]=cmd[1..-1]
    self[:cid]=cmd.join(':') # Used by macro
    [:label,:nocache,:response].each{|k,v|
      self[k]=@db[k][id] if @db.key?(k)
    }
    if @db.key?(:parameter) && par=@db[:parameter][id]
      unless par.size < cmd.size
        Msg.err("Parameter shortage (#{par.size})",@list[id])
      end
      par.size.times{|i|
        validate(self[:param][i],par[i])
      }
    end
    self[:select]=deep_subst(@db[:select][id])
    self
  end

  def subst(str) # par={ val,range,format } or String
    return str unless /\$([\d]+)/ === str
    @v.msg(1){"Substitute from [#{str}]"}
    begin
      res=str.gsub(/\$([\d]+)/){
        i=$1.to_i
        @v.msg{"Parameter No.#{i} = [#{self[:param][i-1]}]"}
        self[:param][i-1] || Msg.err(" No substitute data ($#{i})")
      }
      res=eval(res).to_s unless /\$/ === res
      Msg.err("Nil string") if res == ''
      res
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
      puts Command.new(adb.cover_frm(true)[:cmdframe]).set(ARGV)
    else
      puts Command.new(adb[:command]).set(ARGV)
    end
  rescue
    warn "USAGE: #{$0} (-f) [id] [cmd] (par)"
    Msg.exit
  end
end
