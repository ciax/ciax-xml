#!/usr/bin/ruby
# For Macro Line (Array)

module McrPrt
  def to_s
    return '' if empty?
    map{|h|
      msg='  '*h['depth']
      case h['type']
      when 'break'
        msg << Msg.color('Proceed?',6)+":#{h['label']} -> "
        msg << Msg.color(h['result'] ? "SKIP" : "OK",2)
      when 'check'
        msg << Msg.color('Check',6)+":#{h['label']} -> "
        if h['result']
          msg << Msg.color("OK",2)
        else
          msg << Msg.color("NG",1)+"\n"
          msg << getcond(h)
        end
      when 'wait'
        msg << Msg.color('Waiting',6)+":#{h['label']} -> "
        case h['result']
        when nil
          ret=h['retry'].to_i
          msg << '*'*(ret/10)+'.'*(ret % 10)
        when false
          msg << Msg.color("Timeout(#{h['retry']})",1)+"\n"
          msg << getcond(h)
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
    }.join("\n")
  end

  private
  def getcond(h)
    msg='  '*(h['depth']+1)
    c=h['all'].last
    msg << Msg.color("#{c['ins']}:#{c['var']}",3)+" is not #{c['val']}"
  end
end
