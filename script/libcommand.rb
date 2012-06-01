#!/usr/bin/ruby
require 'libexenum'
require 'libmsg'
require 'librerange'
require 'liblogging'

#Access method(Plan)
#Command(Hash)
# Command#new(db,&def_proc)
# Command#list
# Command#add_group(key,title,&def_proc)
# Command#add_item(key,id,title,&local_proc)
#Command[id]=Command::Item(Hash)
# Command[id] => {:label,:parameter,...}
# Command[id]#set_par(par)
# Command[id]#subst(str)
# Command[id]#exe => proc{}
# Command#set(cmd=alias+par) => Command[alias->id]#set_par(par)

# Keep current command and parameters
class Command < ExHash
  extend Msg::Ver
  attr_reader :list
  attr_accessor :def_proc
  # mandatory (:select)
  # optional (:alias,:label,:parameter)
  # optionalfrm (:nocache,:response)
  def initialize(db,&def_proc)
    Command.init_ver(self)
    @db=Msg.type?(db,Hash)
    @def_proc=def_proc
    @list=Msg::GroupList.new(db)
    db[:select].keys.each{|id|
      self[id]=Item.new(id){def_proc.call}.update(db_pack(db,id))
    }
    @group={}
    if gdb=db[:group]
      gdb[:select].each{|gid,ary|
        cap=(gdb[:caption]||{})[gid]
        col=(gdb[:column]||{})[gid]
        @group[gid]=Group.new(cap,col,2)
        ary.each{|id|
          @group[gid]=self[id]
        }
      }
    else
      @group['main']=Group.new("Command List",2,2)
    end
    @chk=proc{}
  end

  def add_group(gid,title,&def_proc)
    @group[gid]=Group.new(title,2){def_proc.call}
  end

  #hash = {:label => 'titile',:parameter => Array}
  def add_item(gid,id,title=nil,parlist=nil,&local_proc)
    self[id]=Item.new(id){local_proc.call}
    self[id][:label]=title if title
    self[id][:parameter]=parlist if parlist
    @group[gid]=self[id]
    self
  end

  def set_pre_proc
    @chk=proc{|cmd| yield cmd}
    self
  end

  def set(cmd)
    id,*par=cmd
    id=a2r(id)
    key?(id) || @list.error
    self[id].set_par(par)
  end

  def ext_logging(id,ver=0)
    extend Logging
    init('appcmd',id,ver){yield}
    self
  end

  private
  def db_pack(db,id)
    hash={}
    db.each{|sym,h|
      case sym
      when :group,:alias
        next
      else
        hash[sym]=h[id].dup if h.key?(id)
      end
    }
    hash
  end

  # alias to real
  def a2r(id)
    @db.key?(:alias) ? @db[:alias][id] : id
  end
end

class Command::Group < Hash
  attr_reader :list
  def initialize(title,col=2,color=6,&def_proc)
    @list=Msg::CmdList.new(title,col,color)
    @def_proc=def_proc
  end

  def add_item(id,hash)
    self[id]=hash
    @list.update({id => hash[:label]})
    self
  end

  # hash = {id => title,...}
  def update_items(hash,&local_proc)
    @list.update(hash)
    local_proc||=@def_proc
    hash.each{|id,title|
      self[id]=Item.new(id){local_proc.call}
    }
    self
  end
end

# Validate command and parameters
class Command::Item < Hash
  include Math
  attr_accessor :exe
  def initialize(id,&local_proc)
    @id=id
    @exe=local_proc if local_proc
  end

 def set_par(par)
    @par=Msg.type?(par,Array)
    num_validate(par)
    @select=deep_subst(self[:select])
    self[:cid]=[@id,*par].join(':') # Used by macro
    Command.msg{"SetPAR: #{par}"}
    self[:msg]='OK'
    self
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

  def to_s
    Msg.view_struct(@select)
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

  def str_validate(cary)
    validate(cary){|str,cri|
      Command.msg{"Validate: [#{str}] Match? [#{cri}]"}
      unless /^(#{cri})/ === str
        Msg.err("Parameter Invalid (#{str}) for [#{cri}]")
      end
      str
    }
  end

  def num_validate(cary)
    validate(cary){|str,cri|
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

  def validate(cary)
    par=@par.dup
    self[:parameter].map{|cri|
      if str=par.shift
        yield(str,cri)
      else
        Msg.err("Parameter shortage (#{@par.size}/#{self[:parameter].size})",
                Msg.item(@id,self[:label])," "*10+"key=(#{cri.tr('|',',')})")
      end
    } if key?(:parameter)
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
  rescue UserError
    Msg::usage("(opt) [id] [cmd] (par)",*$optlist)
    Msg.exit
  end
end
