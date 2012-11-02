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
    attr_reader :id,:par,:cmd,:select,:def_proc
    def initialize(id,index,def_proc=[])
      @id=id
      @index=Msg.type?(index,Command)
      @par=[]
      @cmd=[]
      @select={} #destroyable
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
      @select=deep_subst(self[:select])
      @cmd=[@id,*par]
      self[:cid]=@cmd.join(':') # Used by macro
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
          @par[i-1] || Msg.cfg_err(" No substitute data ($#{i})")
        }
        res=eval(res).to_s unless /\$/ === res
        Msg.cfg_err("Nil string") if res == ''
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
