#!/usr/bin/ruby
require 'libenumx'

module CIAX
  # Macro Layer
  module Mcr
    # Element of Record
    class Interlock < Hashx
      include PrtShare
      def initialize(cond,dev_list,step)
        super()
        @dev_list = type?(dev_list, App::List)
        @condition = cond
        @step = step
      end

      # Sub methods
      def ok?(t = nil, f = nil)
        stats = scan
        conds = @condition.map do|h|
          cond = {}
          site = cond['site'] = h['site']
          var = cond['var'] = h['var']
          stat = stats[site]
          cmp = cond['cmp'] = h['cmp']
          cri = cond['cri'] = h['val']
          form = cond['form'] = h['form']
          case form
          when 'class', 'msg'
            warning("No key value [#{var}] in Status[#{form}]") unless stat[form].key?(var)
            real = stat[form][var]
          when 'data'
            real = stat.get(var)
          else
            warning('No form specified')
          end
          verbose { "site=#{site},var=#{var},form=#{form},cmp=#{cmp},cri=#{cri},real=#{real}" }
          cond['real'] = real
          cond['res'] = match?(real, cri, cond['cmp'])
          cond
        end
        res = conds.all? { |h| h['res'] }
        @step['conditions'] = conds
        @step['result'] = (res ? t : f) if t || f
        res
      end

      def scan
        sites.each_with_object({}) do|site, hash|
          verbose { "Scanning Status #{site}" }
          hash[site] = @dev_list.get(site).stat
        end
      end

      def refresh
        sites.each do|site|
          verbose { "Refresh Status #{site}" }
          @dev_list.get(site).stat.refresh
        end
      end

      def sites
        @condition.map { |h| h['site'] }.uniq
      end

      def match?(real, cri, cmp)
        case cmp
        when 'equal'
          cri == real
        when 'not'
          cri != real
        when 'match'
          /#{cri}/ =~ real
        when 'unmatch'
          /#{cri}/ !~ real
        else
          false
        end
      end
    end
  end
end
