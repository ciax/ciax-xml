#!/usr/bin/ruby
require 'libexenum'
require 'libmsg'
require 'librerange'
require 'liblogging'

# Keep current command and parameters
class Command < ExHash
  extend Msg::Ver
  include Math
  attr_reader :list
  # mandatory (:select)
  # optional (:alias,:label,:parameter)
  # optionalfrm (:nocache,:response)
  def initialize(db)
    Command.init_ver(self)
    @db=Msg.type?(db,Hash)
    @list=Msg::GroupList.new(db)
  end

  # Validate command and parameters
  def set(cmd)
    clear
    @list.error("No CMD") if cmd.empty?
    id,*par=Msg.type?(cmd,Array)
    yield id if defined? yield
    [:alias,:parameter,:label,:nocache,:response,:select].each{|key|
      next unless @db.key?(key) && val=@db[key][id]
      case key
      when :alias
        id=val
      when :parameter
        if val.size > par.size
          Msg.err("Parameter shortage (#{self[:par].size})",@list.item(id))
        end
        val.size.times{|i|
          validate(par[i],val[i])
        }
      when :select
        self[:select]=deep_subst(val)
      else
        self[key]=val
      end
    }
    @list.error("No such CMD [#{id}]") if empty?
    self[:par]=par
    self[:cid]=cmd.join(':') # Used by macro
    Command.msg{"SetCMD: #{cmd}"}
    self[:msg]='OK'
    self
  end

  def to_s
    self[:msg].to_s
  end

  # Substitute string($+number) with parameters
  # par={ val,range,format } or String
  # str could include Math functions
  def subst(str)
    return str unless /\$([\d]+)/ === str
    Command.msg(1){"Substitute from [#{str}]"}
    begin
      res=str.gsub(/\$([\d]+)/){
        i=$1.to_i
        Command.msg{"Parameter No.#{i} = [#{self[:param][i-1]}]"}
        self[:par][i-1] || Msg.err(" No substitute data ($#{i})")
      }
      res=eval(res).to_s unless /\$/ === res
      Msg.err("Nil string") if res == ''
      res
    ensure
      Command.msg(-1){"Substitute to [#{res}]"}
    end
  end

  def ext_logging(id,ver=0)
    extend Logging
    init('appcmd',id,ver){yield}
    self
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
      Command.msg{"Validate: [#{num}] Match? [#{va}]"}
      va.split(',').each{|r|
        break if ReRange.new(r) == num
      } && Msg.err(" Parameter invalid (#{num}) for [#{va.tr(':','-')}]")
      str=num.to_s
    end
    str
  end
end

module Command::Logging
  def self.extended(obj)
    Msg.type?(obj,Command)
    obj.extend Object::Logging
  end
  def set(cmd)
    super
    append(cmd)
    self
  end
end

module Command::Exe
  def self.extended(obj)
    Msg.type?(obj,Command)
  end

  # content of proc should return String
  def init
    @exe={}
    @db[:select].each{|k,v|
      @exe[k]=proc{|pri| yield pri }
    }
    Command.msg{"Set Default Proc"}
    @chk=proc{}
    self
  end

  def set(cmd)
    super{|id| self[:exe]=@exe[id] if @exe.key?(id) }
    self
  end

  # content of proc should return String
  def add_proc(id,title=nil)
    @list.add_group('int',"Internal Command",{id=>title},2) if title
    @exe[id]=proc{ yield self[:par] }
    Command.msg{"Proc added"}
    self
  end

  def chk_proc
    @chk=proc{|cmd| yield cmd}
    self
  end

  def exe(pri=1)
    self[:msg]=self[:exe].call(pri)
    self
  end
end

if __FILE__ == $0
  require 'libinsdb'
  Msg.getopts("af")
  begin
    adb=Ins::Db.new(ARGV.shift).cover_app
    if $opt["f"]
      puts Command.new(adb.cover_frm[:cmdframe]).set(ARGV)
    else
      puts Command.new(adb[:command]).set(ARGV)
    end
  rescue
    Msg::usage("(opt) [id] [cmd] (par)",*$optlist)
    Msg.exit
  end
end
