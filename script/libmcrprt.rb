#!/usr/bin/ruby
# For Macro Line (Array)

module CIAX
  module Mcr
    module PrtShare
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

      def body(msg,col=5)
        rindent(1)+Msg.color(msg,col)
      end

      def rindent(add=0)
        Msg.indent(self['depth'].to_i+add)
      end
    end
  end
end
