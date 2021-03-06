#!/usr/bin/env ruby
require 'libmsg'
module CIAX
  # View enum contents
  module View
    # Enumurable Data Handling
    module Enum
      # Array handling
      def __show_ary(data, col)
        if data.any? { |v| v.is_a?(Enumerable) }
          data.each_with_index { |v, i| __recursive(v, i) }
          @lines << __indent
        elsif data.size > col
          ___ary_fold(data, col)
        else
          @lines.last << ___ary_line(data) + ' ' unless data.empty?
        end
      end

      def ___ary_fold(data, col)
        @lines << data.each_slice(col).map do |a|
          __indent(___ary_line(a), 2)
        end.join(",\n") << __indent
      end

      def ___ary_line(a)
        ' ' + a.map(&:inspect).join(', ')
      end

      # Hash handling
      def __show_hash(data, tag)
        if data.values.any? { |v| v.is_a?(Enumerable) }
          data.each { |k, v| __recursive(v, k) }
        else
          data.keys.each_slice(tag ? @cfg[:hash_col] : 1) do |a|
            @lines << __indent(___hash_line(a, data), 1)
          end
        end
      end

      def ___hash_line(a, data)
        a.map do |k|
          format('%-8s: %-10s', __mk_tag(k), __mk_elem(data[k]))
        end.join("\t")
      end

      # Show Tag
      def __mk_tag(tag)
        case tag
        when Numeric
          colorize("[#{tag}]", 6)
        when String
          colorize(tag.inspect, 5)
        else # Symbol
          colorize(tag.inspect, 3)
        end
      end
    end

    # Show data structure
    class Struct
      include Msg
      include Enum
      COLOR_TBL = { 'true' => 13, 'false' => 8 }.freeze
      # show_iv = Show Instance Variable
      # show_id = Show object_id at each element
      # show_cls = Show class of each emement
      def initialize(obj, show_iv = false, show_id = false, show_cls = true)
        @obj = obj
        @opt = { show_iv: show_iv, show_id: show_id, show_cls: show_cls }
        @cfg = { indent: 0, column: 4, hash_col: 2 }
      end

      # Show only top level of the instance variable
      def to_s
        @objects = []
        @lines = []
        __recursive(@obj)
        @lines.join("\n")
      end

      private

      def __indent(str = '', offset = 0)
        indent(@cfg[:indent] + offset) + str
      end

      def __recursive(data, tag = nil)
        @lines << ___get_title(data, tag)
        ___show_iv(data)
        ___sub_structure(data, tag)
      end

      def ___get_title(data, tag)
        tag ? __indent(___get_tag(data, tag)) : "<<#{data.class}>>"
      end

      # Make Line Head
      def ___get_tag(data, tag)
        str = format('%-6s :', __mk_tag(tag))
        # Add Id
        if data.is_a?(Enumerable)
          if @opt[:show_cls] && /::/ =~ data.class.to_s
            str << colorize("<#{data.class}>", 2)
          end
          str << colorize("(#{data.object_id})", 4) if @opt[:show_id]
        end
        str
      end

      # Make Instance Variable List for sub structure
      def ___show_iv(data)
        return unless @opt[:show_iv]
        @opt[:show_iv] = nil
        data.instance_variables.reject { |n| /^@_vs_/ =~ n.to_s }.each do |n|
          val = data.instance_variable_get(n).inspect
          @lines << __indent(format('%-8s: %-10s', colorize(n.to_s, 1), val))
        end
      end

      # Show Sub structure
      def ___sub_structure(data, tag)
        @cfg[:indent] += 1
        ___loop?(data) || ___show_all(data, tag)
      ensure
        @cfg[:indent] -= 1
      end

      # Check Loop
      def ___loop?(data)
        return unless data.is_a?(Enumerable)
        # Abort tracking down if duplicated object_id
        if @objects.include?(data.object_id)
          @lines << " #{data.class}(Loop)"
        else
          @objects << data.object_id
          nil
        end
      end

      # Show container
      def ___show_all(data, tag)
        case data
        when Array
          @lines.last << ' ['
          __show_ary(data, @cfg[:column])
          @lines.last << ']'
        when Hash
          __show_hash(data, tag)
        else
          # Show String, Numerical ...
          @lines.last << ' ' + __mk_elem(data)
        end
      end

      # Show Element
      def __mk_elem(data)
        (c = COLOR_TBL[data.to_s]) && colorize(data, c) || data.inspect
      end
    end
  end
end
