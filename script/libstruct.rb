#!/usr/bin/ruby
require 'libmsg'
module CIAX
  # Show data structure
  module ViewStruct
    include Msg

    COLOR_TBL = { 'true' => Msg.colorize('true', 13), 'false' => Msg.colorize('false', 8) }
    def view_struct(show_iv = false, show_id = false, depth = 1)
      @ind = 0
      @column = 4
      _recursive(self, nil, [], show_iv, show_id, depth)
    end

    private

    def _recursive(data, title, object_ary, show_iv, show_id, depth)
      str = ''
      id = data.object_id
      if title
        _show_title(title, str)
        str << colorize("(#{id})", 4) if show_id && data.is_a?(Enumerable)
        str << " :\n"
      else
        str << "<<#{data.class}>>\n"
      end
      _sub_structure(data, title, str, object_ary, show_iv, show_id, depth)
    end

    def _show_title(title, str)
      case title
      when Numeric
        title = "[#{title}]"
        str << indent(@ind) + colorize(format('%-6s', title), 6)
      when /@/
        str << indent(@ind) + colorize(format('%-6s', title.inspect), 1)
      else
        c = title.is_a?(String) ? 5 : 2
        str << indent(@ind) + colorize(format('%-6s', title.inspect), c)
      end
    end

    def _sub_structure(data, title, str, object_ary, show_iv, show_id, depth)
      @ind += 1
      iv = {}
      data.instance_variables.each do|n|
        iv[n] = data.instance_variable_get(n) unless n == :object_ids
        depth -= 1 # Show only top level of the instance variable
      end if show_iv && depth > 0
      _show(str, iv, object_ary, title, show_iv, show_id, depth)
      _show(str, data, object_ary, title, show_iv, show_id, depth)
    ensure
      @ind -= 1
    end

    def _show(str, data, object_ary, title, show_iv, show_id, depth)
      if data.is_a?(Enumerable)
        if object_ary.include?(data.object_id)
          return str.chomp + " #{data.class}(Loop)\n"
        else
          object_ary << data.object_id
        end
      end
      case data
      when Array
        return str if _mixed?(str, data, data, data.size.times, object_ary, show_iv, show_id, depth)
        return _only_ary(str, data) if data.size > @column
      when Hash
        return str if _mixed?(str, data, data.values, data.keys, object_ary, show_iv, show_id, depth)
        return _only_hash(str, data, title) if data.size > 2
      end
      data = COLOR_TBL[data] || data.inspect
      str.chomp + " #{data}\n"
    end

    def _mixed?(str, data, vary, idx, object_ary, show_iv, show_id, depth)
      return unless vary.any? { |v| v.is_a?(Enumerable) }
      idx.each do|i|
        str << _recursive(data[i], i, object_ary, show_iv, show_id, depth)
      end
    end

    def _only_ary(str, data)
      str << indent(@ind) + '['
      line = []
      data.each_slice(@column) do|a|
        line << a.map(&:inspect).join(',')
      end
      str << line.join(",\n " + indent(@ind)) + "]\n"
    end

    def _only_hash(str, data, title)
      data.keys.each_slice(title ? 2 : 1) do|a|
        str << indent(@ind) + a.map do|k|
          c = k.is_a?(String) ? 5 : 3
          colorize(format('%-8s', k.inspect), c) + format(': %-10s', data[k].inspect)
        end.join("\t") + "\n"
      end
      str
    end
  end
end
