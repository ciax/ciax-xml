#!/usr/bin/ruby
require 'libenumx'
# Display: Sortable Caption Database (Value is String)
#   New feature: can make recursive groups
#   Shows visiual command list categorized by sub-group
#   Holds valid command list in @valid_keys
#   Used by Command and XmlDoc
module CIAX
  # Index of Display (Used for validation, display)
  class Disp < Hashx
    # Grouping class (Used for setting db)
    #   Attributes (all level): column(#), line_number(t/f)
    #   Attributes (one level): child(module), color(#), indent(#)
    #   Attributes (one group): caption(text), members(array)
    SEPTBL = [['****', 2], ['===', 6], ['--', 9], ['_', 14]]
    attr_reader :valid_keys, :sub
    def initialize(atrb = {})
      @valid_keys = Arrayx.new
      @sub = nil
      @atrb = atrb
    end

    def put_sec
      return @sub if @sub.is_a? Section
      @sub = Section.new(self, @atrb)
    end

    def put_grp
      return @sub if @sub.is_a? Group
      @sub = Group.new(self, @atrb)
    end

    def put_item(k, v)
      @valid_keys << k
      put(k, v)
    end

    def merge_sub(other)
      put_sec.merge_sub(type?(other,Disp).sub)
      self
    end

    # For ver 1.9 or more
    def sort!
      @valid_keys.sort!
      self
    end

    # Reset @valid_keys(could be shared)
    def reset!
      @valid_keys.concat(keys).uniq!
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

    def to_s
      @sub ? @sub.view : view
    end

    def view(select = @valid_keys, atrb = {})
      atrb = @atrb.dup.update(atrb)
      list = {}
      (@valid_keys & select).compact.sort.each_with_index do|id, num|
        title = atrb[:line_number] ? "[#{num}](#{id})" : id
        list[title] = self[id]
      end
      return if list.empty?
      columns(list, atrb[:column], atrb[:level], mk_caption(atrb))
    end

    def mk_caption(atrb = {})
      return unless atrb[:caption]
      level=atrb[:level] || 0
      sep, col = SEPTBL[level]
      indent(level) +
        caption(atrb[:caption], atrb[:color] || col, sep)
    end

    # Parent of Group
    class Section < Hashx
      attr_accessor :index
      def initialize(index, atrb = {})
        @index = index
        @atrb = atrb
      end

      # add sub caption if sub is true
      def put_sec(id, cap, atrb = {})
        return self[id] if self[id]
        level = @atrb[:level].to_i
        level += 1 if @atrb[:caption]
        self[id] = Section.new(@index, caption: cap, level: level, **atrb)
      end

      def put_grp(id, cap, atrb = {})
        return self[id] if self[id]
        level = @atrb[:level].to_i
        level += 1 if @atrb[:caption]
        self[id] = Group.new(@index, caption: cap, level: level, **atrb)
      end

      def reset!
        @index.reset!
        self
      end

      def valid?(id)
        @index.valid?(id)
      end

      def view
        ary = values.map(&:view).grep(/./)
        ary.unshift(@index.mk_caption(@atrb)) if @atrb[:caption]
        ary.join("\n")
      end

      def to_s
        view
      end

      def merge_sub(other)
        rec_merge_index(other)
        update(other)
        @index.reset!
      end

      private

      def rec_merge_index(gr)
        type?(gr, Hashx).values.each do |sg|
          rec_merge_index(sg) if sg.is_a? Hashx
          sg.index = @index.update(sg.index)
        end
      end
    end

    # It has members of item
    class Group < Arrayx
      attr_accessor :index
      def initialize(index, atrb = {})
        @index = index
        @atrb = atrb
      end

      # add item
      def put_item(k, v)
        push k
        @index.valid_keys << k
        @index[k] = v
      end

      def reset!
        @index.reset!
        self
      end

      def valid?(id)
        @index.valid?(id)
      end

      def view
        @index.view(self, @atrb)
      end

      def to_s
        view.to_s
      end
    end
  end

  if __FILE__ == $PROGRAM_NAME
    # Top level only
    grp0 = Disp.new(caption: 'top',column: 3)
    10.times { |i| grp0.put_item("x#{i}", "caption #{i}") }
    puts grp0.view
    puts
    # Three level groups
    grp1 = Disp.new(column: 3, caption: 'top1', color: 4).put_sec
    2.times do |i|
      s11 = grp1.put_sec("g#{i}", "Group#{i}")
      3.times do |j|
        s12 = s11.put_grp("sg#{j}", "SubGroup#{j}", color: 1)
        4.times do |k|
          cstr = '*' * rand(5)
          s12.put_item("#{i}-#{j}-#{k}", "caption#{i}-#{j}-#{k},#{cstr}")
        end
      end
    end
    puts grp1
    puts
    # Two level groups with item number
    grp2 = Disp.new(line_number: true).put_sec
    3.times do |i|
      s21 = grp2.put_grp("g2#{i}", "Gp#{i}")
      3.times do |j|
        cstr = '*' * rand(5)
        s21.put_item("#{i}-#{j}", "cp#{i}-#{j},#{cstr}")
      end
    end
    puts grp2
    puts
    # Merging groups
    grp1.merge_sub(grp2)
    puts grp1
    puts
    # Confirm merged index
    grp1.index.valid_keys.delete('0-0')
    puts grp1
  end
end
