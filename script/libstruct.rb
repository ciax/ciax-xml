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
      @lines = []
      # Show only top level of the instance variable
      _recursive(self, nil)
      @lines.join("\n")
    end

    private

    def _recursive(data, item)
      id = data.object_id
      if item
        str = _indent(_mk_head(item))
        str << colorize("(#{id})", 4) if @_vs_show_id && data.is_a?(Enumerable)
        @lines << str + ' :'
      else
        @lines << "<<#{data.class}>>"
      end
      _mk_iv_list
      _sub_structure(data, item)
    end

    def _mk_head(item)
      case item
      when Numeric
        item = "[#{item}]"
        colorize(format('%-6s', item), 6)
      when /@/
        colorize(format('%-6s', item.inspect), 1)
      else
        c = item.is_a?(String) ? 5 : 2
        colorize(format('%-6s', item.inspect), c)
      end
    end

    def _mk_iv_list
      return unless @_vs_show_iv
      instance_variables.each do|n|
        @_vs_iv_list[n] = instance_variable_get(n) unless /_vs_/ =~ n.to_s
      end
      @_vs_show_iv = nil
    end

    def _sub_structure(data, item)
      @_vs_indent += 1
      #      _show_all(@_vs_iv_list, item)
      _show_all(data, item)
    ensure
      @_vs_indent -= 1
    end

    def _show_all(data, item)
      return if _chk_loop(data)
      return true if _show_enum(item, data)
      color = COLOR_TBL[data.to_sym] if data.is_a? String
      data = color ? colorize(data, color) : data.inspect
      @lines.last << " #{data}"
    end

    def _chk_loop(data)
      return unless data.is_a?(Enumerable)
      if @_vs_objects.include?(data.object_id)
        @lines << " #{data.class}(Loop)"
      else
        @_vs_objects << data.object_id
        nil
      end
    end

    def _show_enum(item, data)
      case data
      when Array
        _show_array(data)
      when Hash
        _show_hash(data, item)
      end
    end

    def _show_array(data)
      return true if _mixed?(data, data, data.size.times)
      return unless data.size > @_vs_column
      _only_ary(data)
    end

    def _show_hash(data, item)
      return true if _mixed?(data, data.values, data.keys)
      return unless data.size > 2
      _only_hash(data, item)
    end

    def _mixed?(data, vary, idx)
      return unless vary.any? { |v| v.is_a?(Enumerable) }
      idx.each do|i|
        _recursive(data[i], i)
      end
    end

    def _only_ary(data)
      @lines << _indent('[')
      line = []
      data.each_slice(@_vs_column) do|a|
        line << _indent(' ') + a.map(&:inspect).join(',')
      end
      @lines << line.join(",\n")
      @lines << _indent(']')
    end

    def _only_hash(data, item)
      data.keys.each_slice(item ? 2 : 1) do|a|
        @lines << _indent(_hash_line(a, data))
      end
    end

    def _hash_line(a, data)
      a.map do|k|
        c = k.is_a?(String) ? 5 : 3
        val = format(': %-10s', data[k].inspect)
        colorize(format('%-8s', k.inspect), c) + val
      end.join("\t")
    end

    def _indent(str = '')
      indent(@_vs_indent) + str
    end
  end
end
