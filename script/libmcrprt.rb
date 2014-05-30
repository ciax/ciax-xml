#!/usr/bin/ruby
# For Macro Line (Array)

module CIAX
  module Mcr
    module Prt
      def head(msg,col)
        label=self['label']||self['site']||'noname'
        msg=Msg.indent(self['depth'].to_i)+Msg.color(msg,col)+':'
        if key?('args')
          msg << self['args'].join(' ')+'('+label+')'
        else
          msg << label
        end
        msg
      end

      def body(msg,col=5)
        Msg.indent(self['depth'].to_i+1)+Msg.color(msg,col)
      end
    end

    module PrtRecord
      include Prt
      def to_s
        msg=head("MACRO",3)+"\n"
        @data.each{|i|
          i.extend(PrtStep) unless i.is_a?(PrtStep)
          msg << i.to_s
        }
        msg
      end
    end

    module PrtStep
      include Prt
      def to_s
        title+result
      end

      def title
        case self['type']
        when 'mesg'
          msg=head('Mesg',5)
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
        mary=['']
        mary[0] << "(#{self['retry']}/#{self['max']})" if self['max']
        if res=self['result']
          title=res.capitalize
          color=(/failed|timeout/ === res) ? 1 : 2
          mary[0] << ' -> '+Msg.color(title,color)
          if c=self['conditions']
            c.each{|h|
              if h['res']
                mary << body("#{h['site']}:#{h['var']}",3)+" is #{h['cmp']}"
              else
                mary << body("#{h['site']}:#{h['var']}",3)+" is not #{h['cmp']}"
              end
            }
          end
        end
        mary << body(self['action'].capitalize,8) if key?('action')
        mary.join("\n")+"\n"
      end
    end
  end
end
