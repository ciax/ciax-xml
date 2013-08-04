#!/usr/bin/ruby
# For Macro Line (Array)

module CIAX
  module Mcr
    module Prt
      def head(msg,col)
        label=self['label']||self['site']
        msg=Msg.indent(self['depth'].to_i)+Msg.color(msg,col)+':'
        if key?('cmd')
          msg << self['cmd'].join(' ')+'('+label+')'
        else
          msg << label
        end
        msg
      end

      def item(msg,col)
        Msg.indent(self['depth'].to_i+1)+Msg.color(msg,col)
      end
    end

    class Record
      include Prt
      def to_s
        msg=head("MACRO",3)+"\n"
        @data.each{|i|
          msg << i.to_s
        }
        msg
      end
    end

    class Step
      include Prt
      def to_s
        title+result
      end

      def title
        case self['type']
        when 'goal'
          msg=head('Done?',6)
        when 'check'
          msg=head('Check',6)
        when 'wait'
          msg=head('Waiting',6)
        when 'mcr'
          msg=head("MACRO",3)
          msg << "(async)" if self['async']
        when 'exec'
          msg=head("EXEC",13)
        end
        msg
      end

      def result
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
                  mary << item("#{h['site']}:#{h['var']}",3)+" is #{h['cmp']}"
                else
                  mary << item("#{h['site']}:#{h['var']}",3)+" is not #{h['cmp']}"
                end
              else
                mary << item("#{h['site']}",3)+" is not updated"
              end
            }
          end
        end
        mary << item(self['action'].capitalize,8) if key?('action')
        mary.join("\n")+"\n"
      end
    end
  end
end
