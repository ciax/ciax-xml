#!/usr/bin/env ruby
module CIAX
  # Config View module
  module ConfigView
    # Show all contents of all generation
    def path(key = nil)
      i = 0
      ary = @generation.map do |h|
        "  [#{i += 1}]{" + ___show_generation(key, h) + "} (#{h.object_id})"
      end
      __decorate(ary.reverse)
    end

    # Show list of all key,val which will be taken with [] access
    def listing
      db = {}
      @generation.each_with_index do |h, i|
        h.each { |k, v| db[k] = [i, v] unless db.key?(k) }
      end
      ary = db.map do |k, a|
        val = ___show_db(a[1])
        "  #{k} (#{a[0]}) = #{val}"
      end
      __decorate(ary.reverse)
    end

    private

    def ___show_db(v)
      return __show(v.inspect) if __any_mod?(v, String, Numeric, Enumerable)
      return __show(v.class) if v.is_a? Proc
      __show(v)
    end

    def __decorate(ary)
      ["******[Config]******(#{object_id})", *ary, '************'].join("\n")
    end

    def ___show_generation(key, h)
      h.map do |k, v|
        next if key && k != key.to_sym
        val = k == :obj ? __show(v.class) : ___show_contents(v)
        "#{k.inspect.sub(/^:/, '')}: #{val}"
      end.compact.join(', ')
    end

    def ___show_contents(v)
      return __show(v.class) if __any_mod?(v, Hash, Proc)
      return ___show_array(v) if v.is_a? Array
      __show(v.inspect)
    end

    def ___show_array(v)
      '[' + v.map do |e|
        __show(e.is_a?(Enumerable) ? e.class : e.inspect)
      end.join(',') + "](#{v.object_id})"
    end

    def __show(v)
      v.to_s.sub('CIAX::', '')
    end

    def __any_mod?(v, *modary)
      modary.any? { |mod| v.is_a? mod }
    end
  end
end
