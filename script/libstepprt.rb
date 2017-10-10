#!/usr/bin/ruby
require 'libstep'
# For Macro Line (Array)
module CIAX
  module Mcr
    # Macro Printing Mix-in module
    module StepPrt
      include Msg
      OPE = { equal: '==', not: '!=', match: '=~', unmatch: '!~' }.freeze
      def self.extended(obj)
        Msg.type?(obj, Hash)
      end

      def ext_prt(base)
        @base = type?(base, Integer)
        _init_title_list
        self
      end

      def title
        type = self[:type]
        args = self[:args].join(':') if key?(:args)
        if @title_list.key?(type.to_sym)
          _head(*@title_list[type.to_sym])
        else
          method('title_' + type).call(args)
        end
      rescue NameError
        Msg.msg("No such type #{type}")
        type
      end

      def result
        mary = [_prt_count]
        _prt_result(self[:result], mary)
        mary.join("\n") + "\n"
      end

      def action
        key?(:action) ? _body(self[:action].capitalize, 8) + "\n" : ''
      end

      # Display section
      def to_v
        title + result + action
      end

      # returns t/f
      def set_result(tmsg, fmsg = nil, tf = true)
        tf = super
        print result if Msg.fg?
        tf
      end

      private

      def _body(msg, col = 5)
        _rindent(5) + Msg.colorize(msg, col)
      end

      def _prt_count
        total = self[:retry] || self[:val]
        total ? "(#{self[:count].to_i}/#{total})" : ''
      end

      def _color_result(res)
        if /failed|timeout/ =~ res
          1
        elsif /query/ =~ res
          5
        else
          2
        end
      end

      def _prt_result(res, mary)
        if res
          cap = res.capitalize
          color = _color_result(res)
          mary[0] << ' -> ' + Msg.colorize(cap, color)
        end
        _prt_conds(mary)
      end

      def _prt_conds(mary)
        (self[:conditions] || {}).each do |h|
          if h[:skip]
            res = _body('!', 6)
          else
            res = h[:res] ? _body('o', 2) : _body('x', _fail_color)
          end
          mary << res + _cond_line(h)
        end
      end

      def _cond_line(h)
        line = " #{h[:site]}:#{h[:var]}(#{h[:form]})"
        cri = h[:cri]
        ope = OPE[h[:cmp].to_sym]
        cri = "/#{cri}/" if ope =~ /~/
        line << " #{ope} #{cri}?"
        line << " (#{h[:real]})" if !h[:res] || ope != '='
        line
      end

      def _head(msg, col, label = 'noname')
        elps = format('[%6.2f]', (self[:time] - @base) * 0.001) + _rindent
        elps + Msg.colorize(msg, col) + ':' + (self[:label] || label)
      end

      def _fail_color
        ['goal', 'bypass'].include?(self[:type]) ? 4 : 1
      end

      def _rindent(add = 0)
        Msg.indent((self[:depth].to_i + add) * 2)
      end

      # Branched functions (instead of case/when semantics)
      def _init_title_list
        @title_list = {
          mesg: ['Mesg', 5], bypass: ['In position?', 6, 'ignore if satisfied'],
          goal: ['Done?', 6, 'skip if satisfied'],
          wait: ['Waiting', 6], upd: ['Update', 10, "[#{self[:site]}]"],
          check: ['Check', 6, 'interlock'], verify: ['Verify', 6, 'at the end'],
          select: ['Select by', 11, "[#{self[:site]}:#{self[:var]}]"],
          sleep: ['Sleeping', 6, "[#{self[:val]}sec]"],
          system: ['System', 13, "[#{self[:val]}]"]
        }
      end

      def title_mcr(args)
        async = self[:async] ? '(async)' : ''
        _head('MACRO', 3, "[#{args}]#{async}")
      end

      def title_exec(args)
        _head('EXEC', 13, "[#{self[:site]}:#{args}]")
      end

      def title_cfg(args)
        _head('Config', 14, "[#{self[:site]}:#{args}]")
      end
    end

    # Mcr Step
    class Step
      def ext_prt(base)
        extend(StepPrt).ext_prt(base)
      end
    end
  end
end
