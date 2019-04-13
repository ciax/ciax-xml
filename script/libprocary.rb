#!/usr/bin/env ruby
require 'libupd'
module CIAX
  # Proc Dic
  # Commit Priority
  #    (propagation from lower layer)
  #  0: timestamp update
  #  1: data conversion
  #  2: file saving/logging
  #  3: propagation to upper layer
  #
  # Update Priority
  #    (propagation from upper layer)
  #  0: loading/status query/propagation to lower layer
  class ProcArray
    include Msg
    def initialize(obj, name = nil)
      super()
      @obj = type?(obj, Upd)
      @name = __mk_id(@obj, name)
      clear
    end

    def call(title = 'ProcArray')
      verbose { cfmt('%s (%s) %S', title, @obj.time_id, view) }
      @list.each do |a|
        a.each do |k, p|
          verbose { cfmt('Calling %s in (%s)', k, @name) }
          p.call(@obj)
        end
      end
      self
    end

    def view
      @list.map(&:keys).flatten
    end

    def clear
      @list = Array.new(5) { {} }
      self
    end

    # Append proc in specified priority dict
    def append(obj, id, pri = 0, &prc)
      verbose { cfmt('Appending in %s [%s]', @name, __mk_id(obj, id)) }
      return self unless (id = __chk_id(obj, id))
      @list[pri][id] = prc
      verbose { cfmt('Appended in %s %S', @name, view) }
      self
    end

    private

    def __mk_id(obj, name)
      ary = obj.class.to_s.downcase.split('::')
      ary.shift
      ary << name.to_s
      ary.join(':')
    end

    def __chk_id(obj, name)
      id = __mk_id(obj, name)
      return id unless @list.any? { |h| h.key?(id) }
      cfg_err("Duplicated id [#{id}] on #{@name}")
    end
  end
end
