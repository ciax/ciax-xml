#!/usr/bin/ruby
# For Macro Line (Array)

module Mcr
  module Prt
    def self.extended(obj)
      Msg.type?(obj,Hash)
    end

    def to_s
      title+result
    end

    def title
      msg=Msg.indent(self['depth'].to_i)
      case self['type']
      when 'goal'
        msg << Msg.color('Done?',6)+":#{self['label']}"
      when 'check'
        msg << Msg.color('Check',6)+":#{self['label']}"
      when 'wait'
        msg << Msg.color('Waiting',6)+":#{self['label']} "
      when 'mcr'
        msg << Msg.color("MACRO",3)
        msg << ":#{self['cmd'].join(' ')}(#{self['label']})"
        msg << "(async)" if self['async']
      when 'exec'
        msg << Msg.color("EXEC",13)
        msg << ":#{self['cmd'].join(' ')}(#{self['site']})"
      end
      msg
    end

    def result
      return "\n" unless res=self['result']
      msg=''
      ret=self['retry']
      msg='*'*(ret/10)+'.'*(ret % 10) if ret
      msg << ' -> '
      title=res.capitalize
      title << "(#{ret})" if ret
      color=(res == 'pass') ? 2 : 1
      msg << Msg.color(title,color)
      msg << getcond
      if self['dryrun']
        msg << "\n"+Msg.indent(self['depth'].to_i+1)
        msg << Msg.color('Dryrun:Proceed',8)
      end
      msg+"\n"
    end

    private
    def getcond
      msg=''
      if c=self['fault']
        c.each{|h|
          msg << "\n"+Msg.indent((self['depth']||0)+1)
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
