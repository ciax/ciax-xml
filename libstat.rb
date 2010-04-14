#!/usr/bin/ruby
module Stat
  
  def symbol(val,set)
    node_with_name('symbol') do |d|
      case d['type']
      when 'range'
        d.each_node do |e|
          min,max=e.text.split(':')
          next if max.to_f < val.to_f
          next if min.to_f > val.to_f
          set.update(e.attr_to_hash)
          break
        end
      else
        d.node_with_text(val) do |e|
          set.update(e.attr_to_hash)
        end
      end
    end
  end

end
