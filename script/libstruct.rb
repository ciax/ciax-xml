#!/usr/bin/ruby
require 'libmsg'
module CIAX
  # Show data structure
  module ViewStruct
    include Msg

    COLOR_TBL = { true: 13, false: 8 }
    def view_struct(show_iv = false, show_id = false)
      @_vs_show_iv = show_iv
      @_vs_show_id = show_id
      @_vs_indent = 0
      @_vs_column = 4
      @_vs_iv_list = {}
      @_vs_objects = []
      @_vs_lines = []
      # Show only top level of the instance variable
      _recursive(self, nil)
      @_vs_lines.join("\n")
    end

    private

    def _indent(str = '', offset = 0)
      indent(@_vs_indent + offset) + str
    end

    def _recursive(data, item)
      if item
        @_vs_lines << _indent(_mk_head(item) + _show_id(data) + ' :')
      else
        @_vs_lines << "<<#{data.class}>>"
      end
      _show_iv
      _sub_structure(data, item)
    end

    # Make Line Head
    def _mk_head(item)
      case item
      when Numeric
        _show_head("[#{item}]", 6)
      when String
        _show_head(item.inspect, 5)
      else
        _show_head(item.inspect, 2)
      end
    end

    def _show_head(str, color)
      colorize(format('%-6s', str), color)
    end

    def _show_id(data)
      return '' unless @_vs_show_id && data.is_a?(Enumerable)
      colorize("(#{data.object_id})", 4)
    end

    # Make Instance Variable List for sub structure
    def _show_iv
      return unless @_vs_show_iv
      @_vs_show_iv = nil
      ivs = {}
      instance_variables.each do|n|
        ivs[n.to_s] = instance_variable_get(n) unless /^@_vs_/ =~ n.to_s
      end
      _iv_list(ivs)
    end

    def _iv_list(ivs)
      ivs.each do |k, v|
        @_vs_lines << _indent(format('%-8s: %-10s', colorize(k, 1), v.inspect))
      end
    end

    # Show Sub structure
    def _sub_structure(data, item)
      @_vs_indent += 1
      return if _loop?(data)
      _show_all(data, item)
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
    def _show_all(data, item)
      case data
      when Array
        _show_array(data)
      when Hash
        _show_hash(data, item)
      else
        # Show String, Numerical ...
        @_vs_lines.last << ' ' + _elem(data)
      end
    end

    def _show_array(data)
      return true if _mixed?(data, data, data.size.times)
      return unless data.size > @_vs_column
      _end_ary(data)
    end

    def _show_hash(data, item)
      return true if _mixed?(data, data.values, data.keys)
      return unless data.size > 2
      _end_hash(data, item)
    end

    def _mixed?(data, vary, idx)
      return unless vary.any? { |v| v.is_a?(Enumerable) }
      idx.each { |i| _recursive(data[i], i) }
    end

    # Array without sub structure
    def _end_ary(data)
      @_vs_lines << _indent('[', 1)
      line = []
      data.each_slice(@_vs_column) do|a|
        line << _indent(a.map(&:inspect).join(','), 2)
      end
      @_vs_lines << line.join(",\n")
      @_vs_lines << _indent(']', 1)
    end

    # Hash without sub structure
    def _end_hash(data, item)
      data.keys.each_slice(item ? 2 : 1) do|a|
        @_vs_lines << _indent(_hash_line(a, data), 1)
      end
    end

    def _hash_line(a, data)
      a.map do|k|
        format('%-8s: %-10s', _elem(k), data[k].inspect)
      end.join("\t")
    end

    # Show String, Numerical
    def _elem(data)
      if data.is_a?(String) && (c = COLOR_TBL[data.to_sym])
        colorize(data, c)
      else
        colorize(data.inspect, 3)
      end
    end
  end
end
