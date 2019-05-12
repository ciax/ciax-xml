#!/usr/bin/env ruby
require 'libupd'
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
    def initialize(obj, name, title = 'ProcArray')
      super()
      @obj = type?(obj, Upd)
      @name = __mk_id(@obj, name)
      @title = title
      clear
    end

    def call(pri = nil)
      verbose { __ver_text(@title, pri) }
      (pri ? [@list[pri.to_i]] : @list).each do |a|
        a.each do |k, p|
          verbose { __ver_text("Calling #{k}", pri) }
          p.call(@obj)
        end
      end
      self
    end

    def to_s
      @list.map { |l| l.keys.inspect }.join("\n")
    end

    def clear
      @list = Array.new(5) { {} }
      self
    end

    # Append proc in specified priority dict
    def append(obj, id, pri = 0, &prc)
      return self unless (id = __chk_id(obj, id))
      @list[pri][id] = prc
      verbose { __ver_text('Appended', pri) }
      self
    end

    private

    def __ver_text(title, pri)
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
