#!/usr/bin/ruby
require 'libenumx'
# CIAX-XML
module CIAX
  # Display: Sortable Caption Database (Value is String)
  #    Shows visiual command list categorized by sub-group
  #    Holds valid command list in @select
  #    Used by Command and XmlDoc
  #    Attribute items : caption(text), color(#),  column(#), line_number(t/f)
  class Display < Hashx
    attr_accessor :select
    def initialize(atrb = {}, select = [])
      @atrb = Msg.type?(atrb, Hash) # atrb can be Config
      @caption = caption(atrb, '****')
      @column = [atrb['column'].to_i, 1].max
      @ln = atrb['line_number']
      # Selected items for display
      @select = type?(select, Array)
      @sub_group = Hashx.new
      new_grp('def')
    end

    def put(k, v, grp = nil)
      @select << k
      @sub_group[grp||'def'][:member] << k
      super(k, v)
    end

    def new_grp(id, caption = nil, color = nil)
      atrb = Hashx.new
      atrb['caption'] = caption if caption
      atrb['color'] = color.to_i if color
      atrb[:member] = []
      @sub_group[id] = atrb
    end

    def merge_group!(other)
      type?(other, List).select = @select
      @sub_group.update(other.group)
      deep_update(other)
      reset!
    end

    # For ver 1.9 or more
    def sort!
      @select.sort!
      self
    end

    # Reset @select(could be shared)
    def reset!
      @select.concat(keys).uniq!
      self
    end

    def clear
      @select.clear
      @sub_group.clear
      super
    end

    def delete(id)
      @sub_group.each_value{|atrb| atrb[:member].delete(id)}
      @select.delete(id)
      super
    end

    def key?(id)
      @select.include?(id)
    end

    def keys
      @select
    end

    def to_s
      all = [@caption]
      @sub_group.each_value do |atrb|
        all << caption(atrb)
        all << make_line(atrb)
      end
      all.grep(/./).join("\n")
    end

    private

    def caption(atrb, sep = '==')
      return '' unless atrb['caption']
      sep + ' ' + Msg.color(atrb['caption'], atrb['color'] || 6) + ' ' + sep
    end

    def make_line(atrb)
      list = {}
      num = 0
      (@select & atrb[:member] & keys).sort.each do|id|
        title = @ln ? "[#{num += 1}](#{id})" : id
        list[title] = self[id]
      end
      Msg.columns(list, @column)
    end
  end

  if __FILE__ == $PROGRAM_NAME
    atrb = { 'caption' => 'TEST', 'column' => 3, 'color' => 2 }
    atrb['line_number'] = true
    dl = Display.new(atrb)
    5.times do |i|
      dl.new_grp("g#{i}", "Group#{i}")
      5.times do |j|
        istr = '+' * rand(5)
        cstr = '*' * rand(5)
        dl.put("#{i}-#{j},#{istr}", "caption#{i}-#{j},#{cstr}", "g#{i}")
      end
    end
    puts dl.to_s
  end
end
