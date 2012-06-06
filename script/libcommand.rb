#!/usr/bin/ruby
require 'libexenum'
require 'libmsg'
require 'librerange'
require 'liblogging'
require 'libupdate'

#Access method(Plan)
#Command(Hash)
# Command::Item => {:label,:parameter,...}
#  Command::Item#set_par(par)
#  Command::Item#subst(str)
#  Command::Item#add_proc{|id,par|}
#
# Command::Group => {id => Command::Item}
#  Command::Group#add_item(id,title){|id,par|} -> Command::Item
#  Command::Group#update_items(list){|id,par|}
#
# Command#new(db)
#  Command#add_group(key,title,&def_proc) -> Command::Group
#  Command#group[key]=Command::Group
#  Command#current=Command::Item
#  Command#pre_exe=Update
#  Command[id]=Command::Item
#  Command#set(cmd=alias+par) =>
#    Command[alias->id]#set_par(par)
#    Command#current=Command[id]
#
# Keep current command and parameters
class Command < ExHash
  extend Msg::Ver
  attr_reader :current,:group,:pre_exe
  # CDB: mandatory (:select)
  # optional (:alias,:label,:parameter)
  # optionalfrm (:nocache,:response)
  def initialize(db)
    Command.init_ver(self)
    @db=Msg.type?(db,Hash)
    @pre_exe=Update.new
    all=db[:select].keys.each{|id|
      self[id]=Item.new(self,id).update(db_pack(db,id))
    }
    @current=nil
    @group={}
    if gdb=db[:group]
      gdb[:items].each{|gid,member|
        cap=(gdb[:caption]||{})[gid]
        col=(gdb[:column]||{})[gid]
        def_group(gid,member,cap,col)
      }
    else
      def_group('main',all,"Command List",1)
    end
  end

  def add_group(gid,title)
    @group[gid]=Group.new(self,title,2)
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
    raise InvalidCMD,str+to_s
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
    (@db[:alias]||{})[id] || id
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
    @group[gid]=Group.new(self,cap,col,2)
    items.each{|id|
      @group[gid][id]=self[id]
    }
    add_list(@group[gid].list,items)
  end

  class Group < Hash
    attr_reader :list
    def initialize(index,title,col=2,color=6)
      @list=Msg::CmdList.new(title,col,color)
      @index=Msg.type?(index,Command)
    end

    def add_item(id,title=nil,parameter=nil)
      @list[id]=title
      @index[id]=self[id]=Item.new(@index,id)
      property={:label => title}
      property[:parameter] = parameter if parameter
      self[id].update(property)
    end

    #property = {:label => 'titile',:parameter => Array}
    def update_items(list)
      @list.update(list)
      list.each{|id,title|
        @index[id]=self[id]=Item.new(@index,id).add_proc{|id,par|
          yield(id,par)
        }
      }
      self
    end
  end

  # Validate command and parameters
  class Item < ExHash
    include Math
    attr_reader :id
    def initialize(index,id)
      @index=Msg.type?(index,Command)
      @id=id
      @par=[]
      @exelist=index.pre_exe.dup
    end

    def add_proc
      @exelist << proc{yield @id,@par}
      self
    end

    def exe
      @exelist.upd.last
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
        Msg.par_err(
                "Parameter shortage (#{pary.size}/#{self[:parameter].size})",
                Msg.item(@id,self[:label]),
                " "*10+"key=(#{cri.tr('|',',')})")
        end
        case par[:type]
        when 'num'
          begin
            num=eval(str)
          rescue Exception
            Msg.par_err("Parameter is not number")
          end
          Command.msg{"Validate: [#{num}] Match? [#{cri}]"}
          cri.split(',').each{|r|
            break if ReRange.new(r) == num
          } && Msg.par_err(" Parameter invalid (#{num}) for [#{cri.tr(':','-')}]")
          num.to_s
        when 'reg'
          Command.msg{"Validate: [#{str}] Match? [#{cri}]"}
          unless /^(#{cri})/ === str
            Msg.par_err("Parameter Invalid (#{str}) for [#{cri}]")
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
