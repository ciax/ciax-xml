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
# Command::Domain => {id => Command::Group}
#  Command::Domain#list -> String
#  Command::Domain#add_group(key,title) -> Command::Group
#  Command::Domain#def_proc ->[{|item|},..]
#  Command::Domain#item(id) -> Command::Item
#
# Command#new(db) => {id => Command::Domain}
#  Command#list -> String
#  Command#add_domain(key,title) -> Command::Domain
#  Command#current -> Command::Item
#  Command#setcmd(cmd=[id,*par]):{
#    Command::Item#set_par(par)
#    Command#current -> Command::Item
#  } -> Command::Item
# Keep current command and parameters
class Command < ExHash
  attr_reader :current
  # CDB: mandatory (:select)
  # optional (:label,:parameter)
  # optionalfrm (:nocache,:response)
  def initialize
    init_ver(self)
    @current=nil
  end

  def add_domain(id,color=2)
    self[id]=Domain.new(color)
  end

  def setcmd(cmd)
    Msg.type?(cmd,Array)
    id,*par=cmd
    grp=group_with_item(id) || error
    grp.valid_keys.include?(id) || error
    @current=grp[id]
    verbose{"SetCMD (#{id},#{par})"}
    @current.set_par(par)
  end

  def list
    values.map{|dom| dom.list}.grep(/./).join("\n")
  end

  def error(str=nil)
    str= str ? str+"\n" : ''
    raise(InvalidCMD,str+list)
  end

  def group_with_item(id)
    values.any?{|dom|
      if grp=dom.group_with_item(id)
        return grp
      end
    }
  end

  class Domain < ExHash
    attr_reader :def_proc
    def initialize(color=2)
      init_ver(self)
      @grplist=[]
      @color=color
      @def_proc=ExeProc.new
    end

    def add_group(gid,caption,column=2)
      attr={'caption' => caption,'column' => column,'color' => @color}
      grp=self[gid]=Group.new(attr,@def_proc)
      @grplist.unshift grp
      grp
    end

    def add_dummy(gid,caption,column=2)
      attr={'caption' => caption,'column' => column,'color' => 1}
      grp=self[gid]=Dummy.new(attr)
      @grplist << grp
      grp
    end

    def reset_proc(&p)
      values.each{|grp|
        grp.reset_proc &p
      }
      self
    end

    def list
      @grplist.map{|grp| grp.list}.grep(/./).join("\n")
    end

    def group_with_item(id)
      values.any?{|grp|
        return grp if grp.key?(id)
      }
    end
  end

  class Dummy < ExHash
    attr_reader :cmdlist
    def initialize(attr)
      @cmdlist=Msg::CmdList.new(attr)
    end

    def add_item(id,title)
      @cmdlist[id]=title
      self
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
    attr_reader :cmdlist,:valid_keys
    attr_accessor :def_proc
    #attr = {caption,color,column,:members}
    def initialize(attr,def_proc=ExeProc.new)
      init_ver(self)
      @attr=Msg.type?(attr,Hash)
      @valid_keys=[]
      @cmdlist=Msg::CmdList.new(attr,@valid_keys)
      @def_proc=Msg.type?(def_proc,ExeProc)
    end

    def add_item(id,title=nil,parameter=nil)
      @cmdlist[id]=title
      item=self[id]=Item.new(id,@def_proc)
      property={:label => title}
      property[:parameter] = parameter if parameter
      item.update(property)
      item
    end

    #property = {:label => 'titile',:parameter => Array}
    def update_items(labels)
      (@attr[:members]||labels.keys).each{|id|
        @cmdlist[id]=labels[id]
        self[id]=Item.new(id,@def_proc)
      }
      self
    end

    def reset_proc(&p)
      @def_proc=ExeProc.new.set &p
      values.each{|v|
        v.reset_proc &p
      }
      self
    end

    def list
      @cmdlist.to_s
    end
  end

  class Item < ExHash
    include Math
    attr_reader :id,:par,:cmd,:def_proc
    def initialize(id,def_proc=ExeProc.new)
      @id=id
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
