#!/usr/bin/ruby
# For Macro Line (Array)

module CIAX
  module Mcr
    module Prt
      def self.extended(obj)
        Msg.type?(obj,Hash)
      end

      def to_s
        msg=title+result
        if st=@data
          st.each{|i|
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
        msg=''
        if res=obj['result']
          msg << ' -> '
          title=res.capitalize
          title << "(#{obj['retry']}/#{obj['max']})" if obj['retry']
          color=(/pass|wait/ === res) ? 2 : 1
          msg << Msg.color(title,color)+"\n"
          if c=obj['conditions']
            c.each{|h|
              msg << Msg.indent(obj['depth'].to_i+1)
              if h['upd']
                if h['res']
                  msg << Msg.color("#{h['site']}:#{h['var']}",3)+" is #{h['cmp']}\n"
                else
                  msg << Msg.color("#{h['site']}:#{h['var']}",3)+" is not #{h['cmp']}\n"
                end
              else
                msg << Msg.color("#{h['site']}",3)+" is not updated\n"
              end
            }
          end
        else
          msg << "\n"
        end
        msg << option(obj)
        msg << action(obj)
      end

      def option(obj=self)
        msg=''
        if opt=obj['option']
          msg << Msg.indent(obj['depth'].to_i+1)
          msg << Msg.color('['+opt.join('/')+']?',5)+"\n"
        end
        msg
      end

      def action(obj=self)
        msg=''
        if act=obj['action']
          msg << Msg.indent(obj['depth'].to_i+1)
          msg << Msg.color(act.capitalize,8)+"\n"
        end
        msg
      end
    end
  end
end
