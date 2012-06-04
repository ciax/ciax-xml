#!/usr/bin/ruby
require 'libexenum'
require 'libmsg'
require 'librerange'
require 'liblogging'

#Access method(Plan)
#Command(Hash)
# Command#new(db)
# Command#def_proc{}
# Command#add_group(key,title,&def_proc)
# Command#add_item(key,id,title,&local_proc)
#Command[id]=Command::Item(Hash)
# Command[id] => {:label,:parameter,...}
# Command[id]#set_par(par)
# Command[id]#subst(str)
# Command[id]#exe => proc{}
# Command#set(cmd=alias+par) => Command[alias->id]#set_par(par)
# Command#current => Command[id]

# Keep current command and parameters
class Command < ExHash
  extend Msg::Ver
  attr_reader :current,:group
  # CDB: mandatory (:select)
  # optional (:alias,:label,:parameter)
  # optionalfrm (:nocache,:response)
  def initialize(db)
    Command.init_ver(self)
    @db=Msg.type?(db,Hash)
    all=db[:select].keys.each{|id|
      self[id]=Item.new(id).update(db_pack(db,id))
    }
    @current=nil
    @group={}
    if gdb=db[:group]
      gdb[:select].each{|gid,member|
        cap=(gdb[:caption]||{})[gid]
        col=(gdb[:column]||{})[gid]
        def_group(gid,member,cap,col)
      }
    else
      def_group('main',all,"Command List",1)
    end
    @chk=proc{}
  end

  def add_group(gid,title,&def_proc)
    @group[gid]=Group.new(title,2){def_proc.call}
    self
  end

  #property = {:label => 'titile',:parameter => Array}
  def add_item(gid,id,title,parameter=nil,&local_proc)
    property={:label => title}
    property[:parameter] = parameter if parameter
    @group[gid].add_item(id,property){local_proc.call}
    self[id]=@group[gid][id]
    self
  end

  def set_pre_proc
    @chk=proc{|cmd| yield cmd}
    self
  end

  def set(cmd)
    id,*par=cmd
    id=a2r(id)
    key?(id) || error
    @current=self[id].set_par(par)
  end

  def ext_logging(id,ver=0)
    extend Logging
    init('appcmd',id,ver){yield}
    self
  end

  def to_s
    @group.values.map{|v| v.list.to_s}.grep(/./).join("\n")
  end

  def error(str=nil)
    str= str ? str+"\n" : ''
    raise SelectCMD,str+to_s
  end

  private
  def db_pack(db,id)
    property={}
    db.each{|sym,h|
      case sym
      when :group,:alias
        next
      else
        property[sym]=h[id].dup if h.key?(id)
      end
    }
    property
  end

  # alias to real
  def a2r(id)
    @db.key?(:alias) ? @db[:alias][id] : id
  end

  # make alias list
  def add_list(list,ary)
    lh=@db[:label]
    if alary=@db[:alias]
      alary.each{|a,r|
        list[a]=lh[r] if ary.include?(r)
      }
    else
      ary.each{|i| list[i]=lh[i] }
    end
    list
  end

  # Make Default groups (generated from Db)
  def def_group(gid,items,cap,col)
    @group[gid]=Group.new(cap,col,2)
    items.each{|id|
      @group[gid][id]=self[id]
    }
    add_list(@group[gid].list,items)
  end

  class Group < Hash
    attr_reader :list
    def initialize(title,col=2,color=6,&def_proc)
      @list=Msg::CmdList.new(title,col,color)
      @def_proc=def_proc
    end

    def add_item(id,property,&local_proc)
      self[id]=Item.new(id){local_proc.call}
      self[id].update(property)
      @list[id]=property[:label]
      self
    end

    # list = {id => title,...}
    def update_items(list)
      @list.update(list)
      list.each{|id,title|
        self[id]=Item.new(id){@def_proc.call}
      }
      self
    end
  end

  # Validate command and parameters
  class Item < ExHash
    include Math
    attr_accessor :exe
    def initialize(id,&local_proc)
      @id=id
      @exe=local_proc if local_proc
    end

    def set_proc
      @exe=proc{yield @par}
      self
    end

    def set_par(par)
      @par=validate(Msg.type?(par,Array))
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

    # Parameter structure {:type,:val}
    def validate(pary)
      pary=Msg.type?(pary.dup,Array)
      return pary unless key?(:parameter)
      self[:parameter].map{|par|
        cri=par[:val]
        unless str=pary.shift
        Msg.err(
                "Parameter shortage (#{pary.size}/#{self[:parameter].size})",
                Msg.item(@id,self[:label]),
                " "*10+"key=(#{cri.tr('|',',')})")
        end
        case par[:type]
        when 'num'
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
        when 'reg'
          Command.msg{"Validate: [#{str}] Match? [#{cri}]"}
          unless /^(#{cri})/ === str
            Msg.err("Parameter Invalid (#{str}) for [#{cri}]")
          end
          str
        end
      }+pary
    end
  end

  module Logging
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
