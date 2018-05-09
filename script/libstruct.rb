#!/usr/bin/ruby
require 'libmsg'
module CIAX
  # Show data structure
  module ViewStruct
    include Msg

    COLOR_TBL = { 'true' => 13, 'false' => 8 }.freeze
    def view_struct(show_iv = false, show_id = false, show_cls = true)
      @_vs_opt = { show_iv: show_iv, show_id: show_id, show_cls: show_cls }
      @_vs_cfg = { indent: 0, column: 4, hash_col: 2 }
      @_vs_objects = []
      @_vs_lines = []
      # Show only top level of the instance variable
      __recursive(self)
      @_vs_lines.join("\n")
    end

    private

    def __indent(str = '', offset = 0)
      indent(@_vs_cfg[:indent] + offset) + str
    end

    def __recursive(data, tag = nil)
      @_vs_lines << ___get_title(data, tag)
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
        if @_vs_opt[:show_cls] && /::/ =~ data.class.to_s
          str << colorize("<#{data.class}>", 2)
        end
        str << colorize("(#{data.object_id})", 4) if @_vs_opt[:show_id]
      end
      str
    end

    # Make Instance Variable List for sub structure
    def ___show_iv(data)
      return unless @_vs_opt[:show_iv]
      @_vs_opt[:show_iv] = nil
      data.instance_variables.reject { |n| /^@_vs_/ =~ n.to_s }.each do |n|
        val = data.instance_variable_get(n).inspect
        @_vs_lines << __indent(format('%-8s: %-10s', colorize(n.to_s, 1), val))
      end
    end

    # Show Sub structure
    def ___sub_structure(data, tag)
      @_vs_cfg[:indent] += 1
      ___loop?(data) || ___show_all(data, tag)
    ensure
      @_vs_cfg[:indent] -= 1
    end

    # Check Loop
    def ___loop?(data)
      return unless data.is_a?(Enumerable)
      # Abort tracking down if duplicated object_id
      if @_vs_objects.include?(data.object_id)
        @_vs_lines << " #{data.class}(Loop)"
      else
        @_vs_objects << data.object_id
        nil
      end
    end

    # Show container
    def ___show_all(data, tag)
      case data
      when Array
        __mixed?(data, data, data.size.times) || ___end_ary(data)
      when Hash
        __mixed?(data, data.values, data.keys) || ___end_hash(data, tag)
      else
        # Show String, Numerical ...
        @_vs_lines.last << ' ' + __mk_elem(data)
      end
    end

    def __mixed?(data, vary, idx)
      return unless vary.any? { |v| v.is_a?(Enumerable) }
      idx.each { |i| __recursive(data[i], i) }
    end

    # Array without sub structure
    def ___end_ary(data)
      head = nil
      @_vs_lines << data.each_slice(@_vs_cfg[:column]).map do |a|
        head = head ? '  ' : '[ '
        __indent(head + a.map(&:inspect).join(','), 1)
      end.join(",\n") + ' ]'
    end

    # Hash without sub structure
    def ___end_hash(data, tag)
      data.keys.each_slice(tag ? @_vs_cfg[:hash_col] : 1) do |a|
        @_vs_lines << __indent(___hash_line(a, data), 1)
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

    # Show Element
    def __mk_elem(data)
      (c = COLOR_TBL[data.to_s]) && colorize(data, c) || data.inspect
    end
  end
end
