#!/usr/bin/ruby
require 'libmsg'
module CIAX
  # Show data structure
  module ViewStruct
    include Msg

    def view_struct(show_iv = false, show_id = false, depth = 1)
      _recursive(self, nil, [], 0, show_iv, show_id, depth)
    end

    private

    def _recursive(data, title, object_ary, ind, show_iv, show_id, depth)
      str = ''
      column = 4
      id = data.object_id
      if title
        case title
        when Numeric
          title = "[#{title}]"
          str << indent(ind) + colorize(format('%-6s', title), 6)
        when /@/
          str << indent(ind) + colorize(format('%-6s', title.inspect), 1)
        else
          str << indent(ind) + colorize(format('%-6s', title.inspect), 2)
        end
        str << colorize("(#{id})", 4) if show_id && data.is_a?(Enumerable)
        str << " :\n"
        ind += 1
      else
        str << "<<#{data.class}>>\n"
      end
      iv = {}
      data.instance_variables.each do|n|
        iv[n] = data.instance_variable_get(n) unless n == :object_ids
        depth -= 1 # Show only top level of the instance variable
      end if show_iv && depth > 0
      _show(str, iv, object_ary, ind, column, title, show_iv, show_id, depth)
      _show(str, data, object_ary, ind, column, title, show_iv, show_id, depth)
    end

    def _show(str, data, object_ary, ind, column, title, show_iv, show_id, depth)
      if data.is_a?(Enumerable)
        if object_ary.include?(data.object_id)
          return str.chomp + " #{data.class}(Loop)\n"
        else
          object_ary << data.object_id
        end
      end
      case data
      when Array
        return str if _mixed?(str, data, data, data.size.times, object_ary, ind, show_iv, show_id, depth)
        return _only_ary(str, data, ind, column) if data.size > column
      when Hash
        return str if _mixed?(str, data, data.values, data.keys, object_ary, ind, show_iv, show_id, depth)
        return _only_hash(str, data, ind, title) if data.size > 2
      end
      str.chomp + " #{data.inspect}\n"
    end

    def _mixed?(str, data, vary, idx, object_ary, ind, show_iv, show_id, depth)
      return unless vary.any? { |v| v.is_a?(Enumerable) }
      idx.each do|i|
        str << _recursive(data[i], i, object_ary, ind, show_iv, show_id, depth)
      end
    end

    def _only_ary(str, data, ind, column)
      str << indent(ind) + '['
      line = []
      data.each_slice(column) do|a|
        line << a.map(&:inspect).join(',')
      end
      str << line.join(",\n " + indent(ind)) + "]\n"
    end

    def _only_hash(str, data, ind, title)
      data.keys.each_slice(title ? 2 : 1) do|a|
        str << indent(ind) + a.map do|k|
          colorize(format('%-8s', k.inspect), 3) + format(': %-10s', data[k].inspect)
        end.join("\t") + "\n"
      end
      str
    end
  end
end
