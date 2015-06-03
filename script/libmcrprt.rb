#!/usr/bin/ruby
# For Macro Line (Array)

module CIAX
  module Mcr
    module PrtShare
      def body(msg,col=5)
        rindent(1)+Msg.color(msg,col)
      end

      def title
        args=self['args'].join(':') if key?('args')
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
          msg=head("MACRO",3,"#{self['label']}(#{args})")
          msg << "(async)" if self['async']
        when 'exec'
          msg=head("EXEC",13,"[#{self['site']}:#{args}]")
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
              res= h['res'] ? body("o",2) : body("x",1)
              ope= h['inv'] ? "!=" : "="
              line=res+" #{h['site']}:#{h['var']} #{ope} #{h['cri']}"
              line+=" (#{h['real']})" if !h['res'] || h['inv']
              mary << line
            }
          end
        end
        mary << body(self['action'].capitalize,8) if key?('action')
        mary.join("\n")+"\n"
      end

      private
      def head(msg,col,label=nil)
        rindent+Msg.color(msg,col)+':'+(label||self['label']||'noname')
      end

      def rindent(add=0)
        Msg.indent(self['depth'].to_i+add)
      end
    end
  end
end
