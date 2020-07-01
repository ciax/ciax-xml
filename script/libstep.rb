#!/usr/bin/env ruby
require 'libupd'
# For Macro Line (Array)
module CIAX
  module Mcr
    # Step constant
    module StepDefine
      OPE = { equal: '==', not: '!=', match: '=~', unmatch: '!~' }.freeze
      Title_Dic = {
        mesg: ['Mesg', 5], bypass: ['Bypass?', 6, 'skip if satisfied'],
        goal: ['Done?', 6, 'skip if satisfied'],
        check: ['Check', 6, 'interlock'], verify: ['Verify', 6, 'at the end']
      }.freeze

      # Branched functions (instead of case/when semantics)
      def __init_title_dic
        {
          upd: ['Update', 10, __sid(:site)],
          system: ['System', 13, __sid(:val)],
          mcr: ['MACRO', 3, __sid(:args, :async)],
          exec: ['EXEC', 13, __sid(:site, :args)],
          cfg: ['Config', 14, __sid(:site, :args)],
          sleep: ['Sleeping(sec)', 6, __sid(:val)],
          select: ['SELECT', 3, __sid(:site, :var)],
          wait: ['Waiting', 6, __sid(:retry)]
        }.update(Title_Dic)
      end

      def __sid(*names)
        proc { a2cid(names.map { |n| self[n] }) }
      end
    end

    # Mcr Step Print
    class Step < Upd
      include StepDefine
      def initialize(base_time)
        super()
        @base_time = type?(base_time, Integer)
        @title_dic = __init_title_dic
      end

      def title_s
        type = self[:type]
        self[:async] = '(async)' if key?(:async)
        ___itemize(*@title_dic[type.to_sym])
      rescue NameError
        Msg.msg("No such type #{type}")
        type
      end

      def select_s
        sel = self[:select]
        return '' unless sel && sel.size == 1
        key, args = sel.first
        "(#{key})=>[#{a2cid(args)}]"
      end

      def result_s
        mary = [___prt_count]
        ___prt_result(self[:result], mary)
        mary.join("\n") + "\n"
      end

      def indent_s(add = 0)
        Msg.indent((self[:depth].to_i + add) * 2)
      end

      def action_s
        return '' unless key?(:action)
        __body(self[:action].capitalize, 8) + "\n"
      end

      # Display section
      def to_v
        title_s + select_s + result_s + action_s
      end

      private

      def __body(msg, col = 5)
        indent_s(5) + Msg.colorize(msg, col)
      end

      def ___prt_count
        total = self[:retry] || self[:val]
        total ? "(#{self[:count].to_i}/#{total})" : ''
      end

      def ___color_result(res)
        { failed: 1, timeout: 1, comerr: 1,
          query: 5, incomplete: 3 }.each do |k, v|
          /#{k}/ =~ res && (return v)
        end
        2
      end

      def ___prt_result(res, mary)
        if res
          cap = res.capitalize
          color = ___color_result(res)
          mary[0] << ' -> ' + Msg.colorize(cap, color)
        end
        ___prt_conds(mary)
      end

      def ___prt_conds(mary)
        (self[:conditions] || {}).each do |h|
          mary << ___cond_result(h) + ___cond_line(h)
        end
      end

      def ___cond_result(h)
        return __body('!', 6) if h[:skip]
        return __body('o', 2) if h[:res]
        __body('x', %w[goal bypass].include?(self[:type]) ? 4 : 1)
      end

      def ___cond_line(h)
        line = " #{h[:site]}:#{h[:var]}(#{h[:form]})"
        cri = h[:cri]
        ope = OPE[h[:cmp].to_sym]
        cri = "/#{cri}/" if ope =~ /~/
        line << " #{ope} #{cri}?"
        line << " (#{h[:real]})" if !h[:res] || ope != '='
        line
      end

      def ___itemize(msg, col, label = '')
        line = ___timestamp + indent_s + Msg.colorize(msg, col) + ':'
        line << self[:label].to_s
        label = label.call if label.is_a?(Proc)
        line << "[#{label}]" unless label.empty?
        line
      end

      def ___timestamp
        format('[%6.2f]', (self[:time] - @base_time) * 0.001)
      end
    end
  end
end
