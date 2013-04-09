#!/usr/bin/ruby
# For Macro Line (Array)
module Mcr
  module Prt
    def self.extended(obj)
      Msg.type?(obj,Hash)
    end

    def to_s
      msg=title+result
      if ary=self['steps']
        ary.each{|i|
          msg << title(i)+result(i)
        }
      end
      msg
    end

    def title(obj=self)
      msg=Msg.indent(obj['depth'].to_i)
      case obj['type']
      when 'goal'
        msg << Msg.color('Done?',6)+":#{obj['label']}"
      when 'check'
        msg << Msg.color('Check',6)+":#{obj['label']}"
      when 'wait'
        msg << Msg.color('Waiting',6)+":#{obj['label']} "
      when 'mcr'
        msg << Msg.color("MACRO",3)
        msg << ":#{obj['cmd'].join(' ')}(#{obj['label']})"
        msg << "(async)" if obj['async']
      when 'exec'
        msg << Msg.color("EXEC",13)
        msg << ":#{obj['cmd'].join(' ')}(#{obj['site']})"
      end
      msg
    end

    def result(obj=self)
      return "\n" unless res=obj['result']
      msg=''
      ret=obj['retry']
      msg='*'*(ret/10)+'.'*(ret % 10) if ret
      msg << ' -> '
      title=res.capitalize
      title << "(#{ret})" if ret
      color=(/pass|wait/ === res) ? 2 : 1
      msg << Msg.color(title,color)
      msg << getcond(obj)
      if obj['action'] == 'dryrun'
        msg << "\n"+Msg.indent(obj['depth'].to_i+1)
        msg << Msg.color('Dryrun:Proceed',8)
      end
      msg+"\n"
    end

    private
    def getcond(obj)
      msg=''
      if c=obj['mismatch']
        c.each{|h|
          msg << "\n"+Msg.indent((obj['depth']||0)+1)
          if h['upd']
            msg << Msg.color("#{h['site']}:#{h['var']}",3)+" is not #{h['cmp']}"
          else
            msg << Msg.color("#{h['site']}",3)+" is not updated"
          end
        }
      end
      msg
    end
  end
end
