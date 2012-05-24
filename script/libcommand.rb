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
    id,*@par=Msg.type?(cmd,Array)
    yield id if defined? yield
    [:alias,:parameter,:label,:nocache,:response,:select].each{|key|
      next unless @db.key?(key) && val=@db[key][id]
      case key
      when :alias
        id=val
      when :parameter
        num_validate(id,val)
      when :select
        self[:select]=deep_subst(val)
      else
        self[key]=val
      end
    }
    @list.error("No such CMD [#{id}]") if empty?
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
        Command.msg{"Parameter No.#{i} = [#{@par[i-1]}]"}
        @par[i-1] || Msg.err(" No substitute data ($#{i})")
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

  def num_validate(id,cary)
    validate(id,cary){|str,cri|
      begin
        num=eval(str)
      rescue Exception
        Msg.err("Parameter is not number")
      end
      Command.msg{"Validate: [#{num}] Match? [#{cri}]"}
      cri.split(',').each{|r|
        break if ReRange.new(r) == num
      } && Msg.err(" Parameter invalid (#{num}) for [#{cri.tr(':','-')}]")
      num.to_s
    }
  end

  def validate(id,cary)
    par=@par.dup
    cary.map{|cri|
      if str=par.shift
        yield(str,cri)
      else
        Msg.err("Parameter shortage (#{@par.size}/#{cary.size})",
                @list.item(id)," "*10+"key=(#{cri.tr('|',',')})")
      end
    }
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
    Msg.type?(obj,Command).init
  end

  def init
    @exe={}
    @parameter={}
    @chk=proc{}
    self
  end

  # content of proc should return String
  def def_proc
    @db[:select].each{|k,v|
      @exe[k]=proc{|pri| yield pri}
    }
    Command.msg{"Set Default Proc"}
    self
  end

  def add_group(id,title)
    @list.add_group(id,title,{},2)
    @defproc[id]=proc{|pri| yield pri} if defined?(yield)
    self
  end

  # content of proc should return String
  def add_case(gid,id,title=nil,*parameter)
    @list.add_items(gid,{id=>title}) if title
    @parameter[id]=parameter unless parameter.empty?
    @exe[id]=defined?(yield) ? proc{ yield @par } : proc{'OK'}
    Command.msg{"Proc added"}
    self
  end

  def pre_proc
    @chk=proc{|cmd| yield cmd}
    self
  end

  def set(cmd)
    @chk.call(cmd)
    super{|id|
      self[:exe]=@exe[id] if @exe.key?(id)
      str_validate(id,@parameter[id]) if @parameter.key?(id)
    }
    self
  end

  def call(pri=1)
    self[:msg]=self[:exe].call(pri) if key?(:exe)
    self
  end

  private
  def str_validate(id,cary)
    validate(id,cary){|str,cri|
      Command.msg{"Validate: [#{str}] Match? [#{cri}]"}
      unless /^(#{cri})/ === str
        Msg.err("Parameter Invalid (#{str}) for [#{cri}]")
      end
      str
    }
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
