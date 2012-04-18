#!/usr/bin/ruby
require 'libexenum'
require 'libmsg'
require 'librerange'

# Keep current command and parameters
class Command < ExHash
  include Math
  attr_reader :list
  # command db (:label,:select,:parameter)
  # frm command db (:nocache,:response)
  def initialize(db)
    @v=Msg::Ver.new(self,2)
    @db=Msg.type?(db,Hash)
    @list=Msg::GroupList.new(db)
  end

  # Validate command and parameters
  def set(cmd)
    id=Msg.type?(cmd,Array).first
    id=(@db.key?(:alias) && @db[:alias][id])||id
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
        Msg.err("Parameter shortage (#{par.size})",@list.get(id))
      end
      par.size.times{|i|
        validate(self[:param][i],par[i])
      }
    end
    self[:select]=deep_subst(@db[:select][id])
    self
  end

  # Substitute string($+number) with parameters
  # par={ val,range,format } or String
  def subst(str)
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
    adb=InsDb.new(ARGV.shift).cover_app
    if opt["f"]
      puts Command.new(adb.cover_frm[:cmdframe]).set(ARGV)
    else
      puts Command.new(adb[:command]).set(ARGV)
    end
  rescue
    Msg::usage("(-fa) [id] [cmd] (par)","-f:frm","-a:app")
    Msg.exit
  end
end
