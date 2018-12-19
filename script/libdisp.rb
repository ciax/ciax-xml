#!/usr/bin/ruby
require 'libhashx'
# Display: Sortable Caption Database (Value is String)
#   Holds valid command list in @valid_keys
#   Used by Command and XmlDoc
module CIAX
  # Index of Display (Used for validation, display)
  class Disp < Hashx
    # Grouping class (Used for setting db)
    #   Attributes (all level): column(#), line_number(t/f)
    #   Attributes (one level): color(#), level(#)
    #   Attributes (one group): caption(text)
    SEPTBL = [['****', 2], ['===', 6], ['--', 12], ['_', 14]].freeze
    attr_reader :valid_keys, :line_number, :dummy_keys
    attr_accessor :num, :rank
    def initialize(caption: nil, color: nil, column: 2, line_number: false)
      @valid_keys = Arrayx.new
      @dummy_keys = Arrayx.new
      @caption = caption
      @color = color
      @column = Array.new(column) { [0, 0] }
      @line_number = line_number
      @num = -1
      @rank = 0
    end

    # New Item
    def put_item(k, v)
      self[k] = v
      @valid_keys << k
      self
    end

    def put_dummy(k, v)
      self[k] = v
      @dummy_keys << k
      self
    end

    # Data Handling
    def sort!
      @valid_keys.sort!
      self
    end

    def reset!
      @valid_keys.replace(keys - @dummy_keys)
      self
    end

    def valid?(id)
      @valid_keys.include?(id)
    end

    def clear
      @valid_keys.clear
      super
    end

    def delete(id)
      @valid_keys.delete(id)
      super
    end

    # Display part
    def to_s
      @num = -1
      view(keys, @caption, @color, @level).to_s
    end

    def item(id)
      itemize(id, self[id])
    end

    def mk_caption(cap, color: nil, level: nil)
      return unless cap
      level = level.to_i
      sep, col = SEPTBL[level]
      indent(level) + [sep, colorize(cap, color || col), sep].join(' ')
    end

    def view(select, cap, color, level)
      hash = {}
      disp_dic = (@valid_keys + @dummy_keys) & select
      disp_dic.compact.each do |id|
        name = @line_number ? "[#{@num += 1}](#{id})" : id
        hash[name] = self[id] if self[id]
      end
      return if hash.empty?
      cap = mk_caption(cap, color: color, level: level)
      columns(hash, @column, level, cap)
    end
  end

  if __FILE__ == $PROGRAM_NAME
    # Top level only
    idx = Disp.new(column: 3, caption: 'top1')
    6.times { |i| idx.put_item("x#{i}", "caption #{i}") }
    puts idx
  end
end
