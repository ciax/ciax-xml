#!/usr/bin/ruby
module ModStat
  
  def symbol(val,set)
    node_with_name('symbol') do |d|
      case d['type']
      when 'range'
        d.each_node do |e|
          min,max=e.text.split(':')
          next if max.to_f < val.to_f
          next if min.to_f > val.to_f
          e.add_attr(set)
          break
        end
      else
        d.node_with_text(val) do |e|
          e.add_attr(set)
        end
      end
    end
  end

end


