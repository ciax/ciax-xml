#!/usr/bin/ruby
require 'libmsg'
module CIAX
  # Show data structure
  module ViewStruct
    include Msg

    COLOR_TBL = { 'true' => 13, 'false' => 8 }.freeze
    def view_struct(show_iv = false, show_id = false)
      @_vs_show_iv = show_iv
      @_vs_show_id = show_id
      @_vs_indent = 0
      @_vs_column = 4
      @_vs_hash_col = 2
      @_vs_objects = []
      @_vs_lines = []
      # Show only top level of the instance variable
      _recursive(self)
      @_vs_lines.join("\n")
    end

    private

    def _indent(str = '', offset = 0)
      indent(@_vs_indent + offset) + str
    end

    def _recursive(data, tag = nil)
      @_vs_lines << if tag
                      _indent(___show_tag(data, tag))
                    else
                      "<<#{data.class}>>"
                    end
      _show_iv(data)
      ___sub_structure(data, tag)
    end

    # Make Line Head
    def ___show_tag(data, tag)
      str = format('%-6s', _mk_tag(tag))
      # Add Id
      if @_vs_show_id && data.is_a?(Enumerable)
        str << colorize("(#{data.object_id})", 4)
      end
      str << ' :'
    end

    # Make Instance Variable List for sub structure
    def _show_iv(data)
      return unless @_vs_show_iv
      @_vs_show_iv = nil
      data.instance_variables.each do |n|
        next if /^@_vs_/ =~ n.to_s
        val = data.instance_variable_get(n).inspect
        @_vs_lines << _indent(format('%-8s: %-10s', colorize(n.to_s, 1), val))
      end
    end

    # Show Sub structure
    def ___sub_structure(data, tag)
      @_vs_indent += 1
      return if _loop?(data)
      ___show_all(data, tag)
    ensure
      @_vs_indent -= 1
    end

    # Check Loop
    def _loop?(data)
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
        _mixed?(data, data, data.size.times) || ___end_ary(data)
      when Hash
        _mixed?(data, data.values, data.keys) || ___end_hash(data, tag)
      else
        # Show String, Numerical ...
        @_vs_lines.last << ' ' + _mk_elem(data)
      end
    end

    def _mixed?(data, vary, idx)
      return unless vary.any? { |v| v.is_a?(Enumerable) }
      idx.each { |i| _recursive(data[i], i) }
    end

    # Array without sub structure
    def ___end_ary(data)
      lines = []
      head = '[ '
      data.each_slice(@_vs_column) do |a|
        lines << _indent(head + a.map(&:inspect).join(','), 1)
        head = '  '
      end
      @_vs_lines << lines.join(",\n") + ' ]'
    end

    # Hash without sub structure
    def ___end_hash(data, tag)
      data.keys.each_slice(tag ? @_vs_hash_col : 1) do |a|
        @_vs_lines << _indent(___hash_line(a, data), 1)
      end
    end

    def ___hash_line(a, data)
      a.map do |k|
        format('%-8s: %-10s', _mk_tag(k), _mk_elem(data[k]))
      end.join("\t")
    end

    # Show Tag
    def _mk_tag(tag)
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
    def _mk_elem(data)
      if (c = COLOR_TBL[data.to_s])
        colorize(data, c)
      else
        data.inspect
      end
    end
  end
end
