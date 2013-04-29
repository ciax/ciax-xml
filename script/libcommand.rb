#!/usr/bin/ruby
require 'libexenum'
require 'libmsg'
require 'librerange'
require 'liblogging'
require 'libupdate'

#Access method
#Command < Hash
# Command::Item => {:label,:parameter,:select,:cmd}
#  Command::Item#set_par(par)
#  Command::Item#reset_proc{|item|}
#
# Command::Group => {id => Command::Item}
#  Command::Group#list -> Msg::CmdList.to_s
#  Command::Group#add_item(id,title){|id,par|} -> Command::Item
#  Command::Group#update_items(list){|id|}
#  Command::Group#def_proc ->[{|item|},..]
#
# Command::Domain => {id => Command::Item}
#  Command::Domain#list -> String
#  Command::Domain#add_group(key,title) -> Command::Group
#  Command::Domain#group[key] -> Command::Group
#  Command::Domain#list -> String
#  Command::Domain#def_proc ->[{|item|},..]
#
# Command#new(db) => {id => Command::Item}
#  Command#list -> String
#  Command#add_domain(key,title) -> Command::Domain
#  Command#domain[key] -> Command::Domain
#   Command#int -> Command::Domain['int']
#  Command#current -> Command::Item
#  Command#def_proc ->[{|item|},..]
#  Command#set(cmd=id+par):{
#    Command[id]#set_par(par)
#    Command#current -> Command[id]
#  } -> Command::Item
# Keep current command and parameters
class Command < ExHash
  attr_reader :current,:domain,:def_proc,:conf
  # CDB: mandatory (:select)
  # optional (:label,:parameter)
  # optionalfrm (:nocache,:response)
  def initialize(conf={:exclude =>'',:include =>'.*'})
    init_ver(self)
    @current=nil
    @domain={}
    @def_proc=ExeProc.new
    @conf=Msg.type?(conf,Hash)
  end

  def add_domain(id,color=2)
    @domain[id]=Domain.new(self,color,@def_proc)
  end

  def setcmd(cmd)
    Msg.type?(cmd,Array)
    id,*par=cmd
    @domain.values.any?{|dom|
      dom.group.values.any?{|grp|
        if grp.cmdlist.valid_key?(id)
          @current=self[id].set_par(par)
        end
      }
    } || error
    verbose{"SetCMD (#{id},#{par})"}
    @current
  end

  def list
    @domain.values.map{|dom| dom.list}.grep(/./).join("\n")
  end

  def error(str=nil)
    str= str ? str+"\n" : ''
    raise(InvalidCMD,str+list)
  end

  class Domain < ExHash
    attr_reader :index,:group,:def_proc
    def initialize(index,color=2,def_proc=ExeProc.new)
      init_ver(self)
      @index=Msg.type?(index,Command)
      @group={}
      @color=color
      @def_proc=Msg.type?(def_proc,ExeProc)
    end

    def add_group(gid,caption,column=2)
      attr={'caption' => caption,'column' => column,'color' => @color}
      @group[gid]=Group.new(@index,attr,@def_proc)
    end

    def add_dummy(gid,caption,column=2)
      attr={'caption' => caption,'column' => column,'color' => @color}
      @group[gid]=Dummy.new(attr)
    end

    def reset_proc(&p)
      values.each{|v|
        v.def_proc.set &p
      }
      self
    end

    def list
      @group.values.map{|grp| grp.list}.grep(/./).join("\n")
    end
  end

  class Dummy < ExHash
    attr_reader :cmdlist
    def initialize(attr)
      @cmdlist=Msg::CmdList.new(attr)
    end

    def update_items(labels)
      labels.each{|k,v|
        @cmdlist[k]=v
      }
      self
    end

    def list
      @cmdlist.to_s
    end
  end

  class Group < ExHash
    attr_reader :cmdlist
    attr_accessor :index,:def_proc
    #attr = {caption,color,column,:members}
    def initialize(index,attr,def_proc=ExeProc.new)
      init_ver(self)
      @attr=Msg.type?(attr,Hash)
      @cmdlist=Msg::CmdList.new(attr)
      @index=Msg.type?(index,Command)
      @def_proc=Msg.type?(def_proc,ExeProc)
    end

    def add_item(id,title=nil,parameter=nil)
      @cmdlist[id]=title
      item=self[id]=Item.new(id,@index,@def_proc)
      property={:label => title}
      property[:parameter] = parameter if parameter
      item.update(property)
      @index.update(self)
      item
    end

    #property = {:label => 'titile',:parameter => Array}
    def update_items(labels)
      (@attr[:members]||labels.keys).each{|id|
        @cmdlist[id]=labels[id]
        self[id]=Item.new(id,@index)
      }
      @index.update(self)
      self
    end

    def reset_proc(&p)
      values.each{|v|
        v.def_proc.set &p
      }
      self
    end

    def list
      @cmdlist.to_s
    end
  end

  class Item < ExHash
    include Math
    attr_reader :index,:id,:par,:cmd,:def_proc
    def initialize(id,index,def_proc=ExeProc.new)
      @id=id
      @index=Msg.type?(index,Command)
      @par=[]
      @cmd=[]
      @def_proc=Msg.type?(def_proc,ExeProc)
    end

    def reset_proc(&p)
      @def_proc=ExeProc.new.set &p
      self
    end

    def exe
      @def_proc.exe(self)
      self
    end

    def set_par(par)
      @par=validate(Msg.type?(par,Array))
      @cmd=[@id,*par]
      self[:cmd]=@cmd.join(':') # Used by macro
      verbose{"SetPAR: #{par}"}
      self
    end

    def to_s
      Msg.item(@id,self[:label])
    end

    private
    # Parameter structure {:type,:val}
    def validate(pary)
      pary=Msg.type?(pary.dup,Array)
      return pary unless self[:parameter]
      self[:parameter].map{|par|
        disp=par[:list].join(',')
        unless str=pary.shift
        Msg.par_err(
                "Parameter shortage (#{pary.size}/#{self[:parameter].size})",
                Msg.item(@id,self[:label]),
                " "*10+"key=(#{disp})")
        end
        case par[:type]
        when 'num'
          begin
            num=eval(str)
          rescue Exception
            Msg.par_err("Parameter is not number")
          end
          verbose{"Validate: [#{num}] Match? [#{disp}]"}
          unless par[:list].any?{|r| ReRange.new(r) == num }
            Msg.par_err("Out of range (#{num}) for [#{disp}]")
          end
          num.to_s
        when 'str'
          verbose{"Validate: [#{str}] Match? [#{disp}]"}
          unless par[:list].include?(str)
            Msg.par_err("Parameter Invalid Str (#{str}) for [#{disp}]")
          end
          str
        when 'reg'
          verbose{"Validate: [#{str}] Match? [#{disp}]"}
          unless par[:list].any?{|r| /#{r}/ === str}
            Msg.par_err("Parameter Invalid Reg (#{str}) for [#{disp}]")
          end
          str
        end
      }
    end
  end
end
