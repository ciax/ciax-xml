#!/usr/bin/ruby
# For Macro Line (Array)

module Mcr
  module Prt
    def to_s
      @line.map{|h|
        single(h)
      }.join("\n")
    end

    def single(h)
      msg='  '*h['depth']
      case h['type']
      when 'break'
        msg << Msg.color('Proceed?',6)+":#{h['label']} -> "
        msg << Msg.color(h['fault'] ? "OK": "SKIP",2)
      when 'check'
        msg << Msg.color('Check',6)+":#{h['label']} -> "
        if h['fault']
          msg << Msg.color("NG",1)+"\n"
          msg << getcond(h)
        else
          msg << Msg.color("OK",2)
        end
      when 'wait'
        msg << Msg.color('Waiting',6)+":#{h['label']} -> "
        if h['timeout']
          msg << Msg.color("Timeout(#{h['retry']})",1)+"\n"
          msg << getcond(h)
        elsif h['fault']
          ret=h['retry'].to_i
          msg << '*'*(ret/10)+'.'*(ret % 10)
        else
          msg << Msg.color("OK",2)
        end
      when 'mcr'
        msg << Msg.color("MACRO",3)+":#{h['cmd'].join(' ')}"
          msg << "(async)" if h['async']
      when 'exec'
        msg << Msg.color("EXEC",13)+":#{h['cmd'].join(' ')}(#{h['ins']})"
      end
      msg
    end

    private
    def getcond(h)
      msg='  '*(h['depth']+1)
      c=h['fault']
      if c['upd']
        msg << Msg.color("#{c['ins']}:#{c['var']}",3)+" is not #{c['val']}"
      else
        msg << Msg.color("#{c['ins']}",3)+" is not updated"
      end
      msg
    end
  end
end
