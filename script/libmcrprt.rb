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
      msg='  '*self['depth']
      case self['type']
      when 'break'
        msg << Msg.color('Done?',6)+":#{self['label']}"
      when 'check'
        msg << Msg.color('Check',6)+":#{self['label']}"
      when 'wait'
        msg << Msg.color('Waiting',6)+":#{self['label']} "
      when 'mcr'
        msg << Msg.color("MACRO",3)+":#{self['cmd'].join(' ')}"
          msg << "(async)" if self['async']
      when 'exec'
        msg << Msg.color("EXEC",13)+":#{self['cmd'].join(' ')}(#{self['site']})"
      end
      msg
    end

    def result
      case self['type']
      when 'break'
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
        msg=' -> '
        if self['timeout']
          msg << Msg.color("Timeout(#{self['retry']})",1)+"\n"
          msg << getcond
        elsif self['fault']
          ret=self['retry'].to_i
          msg << '*'*(ret/10)+'.'*(ret % 10)
        else
          msg << Msg.color("OK",2)
        end
      else
        msg=''
      end
      msg
    end

    private
    def getcond
      msg=''
      if c=self['fault']
        msg << '  '*(self['depth']+1)
        if c['upd']
          msg << Msg.color("#{c['site']}:#{c['var']}",3)+" is not #{c['val']}"
        else
          msg << Msg.color("#{c['site']}",3)+" is not updated"
        end
      end
      msg
    end
  end
end
