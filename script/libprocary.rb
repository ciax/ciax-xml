#!/usr/bin/env ruby
require 'libmsg'
module CIAX
  # Proc Dic
  # Commit Priority
  #    (propagation from lower layer)
  #  0: timestamp update
  #  1: data conversion with lower layer
  #  2: labeling/symbolize data
  #  3: file saving/logging
  #  4: propagation to upper layer
  #
  # Update Priority
  #    (propagation from upper layer)
  #  0: loading/status query/propagation to lower layer
  class ProcArray
    include Msg
    def initialize(obj, name, title = 'ProcArray', psize = 1)
      super()
      @obj = type?(obj, Upd)
      @name = __mk_id(@obj, name)
      @title = title
      @psize = psize.to_i
      clear
    end

    def call
      enclose(__ver_text(@title)) do
        @list.each do |a|
          a.each_value { |p| p.call(@obj) }
        end
      end
      self
    end

    def to_s
      @list.map(&:keys).flatten.inspect
    end

    def clear
      @list = Array.new(@psize) { {} }
      self
    end

    # Append proc in specified priority dict
    def append(obj, id, pri = 0, &prc)
      return self unless (id = __chk_id(obj, id))
      pri = [pri.to_i, @list.size - 1].min
      @list[pri][id] = prc
      verbose { __ver_text('Appended', pri) }
      self
    end

    private

    def __ver_text(title, pri = nil)
      pri = "P#{pri} " if pri
      cfmt("%s in %s #{pri}(%X)\n", title, @name, object_id) + to_s
    end

    def __mk_id(obj, name)
      ary = obj.class.to_s.downcase.split('::')
      ary.shift
      ary << name.to_s
      ary.join(':')
    end

    def __chk_id(obj, name)
      id = __mk_id(obj, name)
      return id unless @list.any? { |h| h.key?(id) }
      cfg_err('Duplicated id [%s](%s) on %s', id, name, @name)
    end
  end
end
