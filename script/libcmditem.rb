#!/usr/bin/ruby
require 'libexenum'
require 'libmsg'
require 'librerange'
require 'liblogging'
require 'libupdate'

#Access method
#Command < Hash
# Command::Item => {:label,:parameter,:select,:cid,:msg}
#  Command::Item#set_par(par)
#  Command::Item#subst(str)
#  Command::Item#init_proc{|item|}
class Command
  class Item < ExHash
    include Math
    attr_reader :id,:par,:cmd
    attr_accessor :def_proc
    def initialize(id,index,def_proc=[])
      @id=id
      @index=Msg.type?(index,Command)
      @par=[]
      @cmd=[]
      @def_proc=Msg.type?(def_proc,Array)
    end

    def init_proc(&p)
      @def_proc=[p]
      self
    end

    def exe
      @def_proc.each{|pr|
        pr.call(self)
      }
      self
    end

    def set_par(par)
      self[:msg]=''
      @par=validate(Msg.type?(par,Array))
      @cmd=[@id,*par]
      self[:cid]=@cmd.join(':') # Used by macro
      Command.msg{"SetPAR: #{par}"}
      self[:msg]='OK'
      self
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
          Command.msg{"Validate: [#{num}] Match? [#{disp}]"}
          unless par[:list].any?{|r| ReRange.new(r) == num }
            Msg.par_err("Out of range (#{num}) for [#{disp}]")
          end
          num.to_s
        when 'str'
          Command.msg{"Validate: [#{str}] Match? [#{disp}]"}
          unless par[:list].include?(str)
            Msg.par_err("Parameter Invalid Str (#{str}) for [#{disp}]")
          end
          str
        when 'reg'
          Command.msg{"Validate: [#{str}] Match? [#{disp}]"}
          unless par[:list].any?{|r| /#{r}/ === str}
            Msg.par_err("Parameter Invalid Reg (#{str}) for [#{disp}]")
          end
          str
        end
      }
    end
  end
end
