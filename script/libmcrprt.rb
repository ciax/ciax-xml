#!/usr/bin/ruby
# For Macro Line (Array)
module Mcr
  module Prt
    def self.extended(obj)
      Msg.type?(obj,Hash)
    end

    def to_s
      msg=title+result+"\n"
      if st=self['steps']
        st.each{|i|
          msg << title(i)+result(i)+"\n"
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
      ary=[]
      if res=obj['result']
        ret=obj['retry']
        msg=ret ? ('*'*(ret/10)+'.'*(ret % 10)) : ''
        msg << ' -> '
        title=res.capitalize
        title << "(#{ret})" if ret
        color=(/pass|wait/ === res) ? 2 : 1
        msg << Msg.color(title,color)
        ary << msg
      end
      if c=obj['mismatch']
        c.each{|h|
          msg = Msg.indent(obj['depth'].to_i+1)
          if h['upd']
            msg << Msg.color("#{h['site']}:#{h['var']}",3)+" is not #{h['cmp']}"
          else
            msg << Msg.color("#{h['site']}",3)+" is not updated"
          end
          ary << msg
        }
      end
      ary << query(obj)
      if act=obj['action']
        msg = Msg.indent(obj['depth'].to_i+1)
        msg << Msg.color(act.capitalize,8)
        ary << msg
      end
      ary.grep(/./).join("\n")
    end

    def query(obj=self)
      msg=''
      if obj[:query]
        msg = Msg.indent(obj['depth'].to_i+1)
        msg << Msg.color(obj[:query],5)
      end
      msg
    end
  end
end
