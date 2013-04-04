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
        msg << ":#{self['cmd'].join(' ')}(#{self['label']} )"
        msg << "(async)" if self['async']
      when 'exec'
        msg << Msg.color("EXEC",13)
        msg << ":#{self['cmd'].join(' ')}(#{self['site']})"
      end
      msg
    end

    def result
      case self['type']
      when 'goal'
        msg=' -> '
        msg << Msg.color(self['fault'] ? "NOT YET": "YES(SKIP)",2)
      when 'check'
        msg=' -> '
        if self['fault']
          msg << Msg.color("NG",1)+"\n"
          msg << getcond
        else
          msg << Msg.color("OK",2)
        end
      when 'wait'
        ret=self['retry'].to_i
        msg='*'*(ret/10)+'.'*(ret % 10)
        if self['result'] == 'timeout'
          msg << ' -> '+Msg.color("Timeout(#{self['retry']})",1)+"\n"
          msg << getcond
        elsif !key?('stat')
          msg << ' -> '+Msg.color("OK",2)
        end
      else
        msg=''
      end
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
          msg << Msg.indent((self['depth']||0)+1)
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
