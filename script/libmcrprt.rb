#!/usr/bin/ruby
# For Macro Line (Array)

module CIAX
  module Mcr
    module PrtShare
      def body(msg,col=5)
        rindent(1)+Msg.color(msg,col)
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
          cap=res.capitalize
          color=(/failed|timeout/ === res) ? 1 : 2
          mary[0] << ' -> '+Msg.color(cap,color)
          if c=self['conditions']
            c.each{|h|
              if h['res']
                mary << body("#{h['site']}:#{h['var']}",3)+" is #{h['cri']}"
              else
                mary << body("#{h['site']}:#{h['var']}",3)+" is not #{h['cri']} (#{h['act']})"
              end
            }
          end
        end
        mary << body(self['action'].capitalize,8) if key?('action')
        mary.join("\n")+"\n"
      end

      def head(msg,col)
        label=self['label']||self['site']||'noname'
        msg=rindent+Msg.color(msg,col)+':'
        if key?('args')
          msg << self['args'].join(' ')+'('+label+')'
        else
          msg << label
        end
        msg
      end

      def rindent(add=0)
        Msg.indent(self['depth'].to_i+add)
      end
    end
  end
end
