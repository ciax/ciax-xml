#!/usr/bin/ruby
# For Macro Line (Array)

module CIAX
  module Mcr
    class Record
      def to_s
        msg=Msg.indent(self['depth'].to_i)
        msg << Msg.color("MACRO",3)
        msg << ":#{self['cmd'].join(' ')}(#{self['label']})\n"
        @data.each{|i|
          msg << i.show_all
        }
      msg
      end
    end

    class Step
      def to_s
        if key?('result')
          msg=show_result
        else
          msg=show_title
        end
        msg
      end

      def show_all
        show_title+show_result
      end

      def show_title
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
          msg << "\n"
        when 'exec'
          msg << Msg.color("EXEC",13)
          msg << ":#{self['cmd'].join(' ')}(#{self['site']})"
        end
        msg
      end

      def show_result
        mary=[]
        if res=self['result']
          title=res.capitalize
          title << "(#{self['retry']}/#{self['max']})" if self['retry']
          color=(/pass|wait/ === res) ? 2 : 1
          mary << ' -> '+Msg.color(title,color)
          if c=self['conditions']
            c.each{|h|
              if h['upd']
                if h['res']
                  mary << ind("#{h['site']}:#{h['var']}",3)+" is #{h['cmp']}"
                else
                  mary << ind("#{h['site']}:#{h['var']}",3)+" is not #{h['cmp']}"
                end
              else
                mary << ind("#{h['site']}",3)+" is not updated"
              end
            }
          end
        end
        mary << show_option
        mary << show_action
        mary.compact.join("\n")+"\n"
      end

      def show_option
        if opt=self['option']
          ind('['+opt.join('/')+']?',5)
        end
      end

      def show_action
        if act=self['action']
          ind(act.capitalize,8)
        end
      end

      private
      def ind(msg,col)
        Msg.indent(self['depth'].to_i+1)+Msg.color(msg,col)
      end
    end
  end
end
