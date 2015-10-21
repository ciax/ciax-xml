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
    attr_accessor :select, :sub_group
    def initialize(atrb = {}, select = [])
      @atrb = Msg.type?(atrb, Hash) # atrb can be Config
      @column = [atrb['column'].to_i, 1].max
      @ln = atrb['line_number']
      atrb['color'] ||= 2
      @caption = caption(atrb, '****')
      # Selected items for display
      @select = type?(select, Array)
      @sub_group = Hashx.new
      new_grp('def')
    end

    def put(k, v, grp = nil)
      @select << k
      @sub_group[grp || 'def'][:members] << k
      super(k, v)
    end

    def new_grp(id, caption = nil, color = nil)
      atrb = Hashx.new
      atrb['caption'] = caption if caption
      atrb['color'] = color.to_i if color
      atrb[:members] = []
      @sub_group[id] = atrb
    end

    def merge_group!(other)
      type?(other, Display).select = @select
      @sub_group.deep_update(other.sub_group)
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
      @sub_group.each_value { |atrb| atrb[:members].delete(id) }
      @select.delete(id)
      super
    end

    def to_s
      all = @sub_group.values.map { |at| make_line(at) }.flatten.compact
      return '' if all.empty?
      all.unshift(@caption) if @caption
      all.join("\n")
    end

    private

    def caption(atrb, sep = '==')
      return unless atrb['caption']
      sep + ' ' + Msg.color(atrb['caption'], atrb['color'] || 6) + ' ' + sep
    end

    def make_line(atrb)
      list = {}
      (@select & atrb[:members] & keys).compact.sort.each_with_index do|id, num|
        title = @ln ? "[#{num}](#{id})" : id
        list[title] = self[id]
      end
      return if list.empty?
      [caption(atrb), Msg.columns(list, @column)]
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
