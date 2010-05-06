#!/usr/bin/ruby
require "libmodfile"
module ModStat
  include ModFile
  def initialize(doc)
    super(doc,'//status')
    begin
      @stat=load_stat(@property['id']) || raise
    rescue
      warn $!
      @stat=Hash.new
    end
  end
  
  def symbol(val,set)
    node_with_name('symbol') do |d|
      case d['type']
      when 'min_base'
        msg "Compare by Minimum Base for [#{val}]"
        d.each_node do |e|
          base=e.text
          msg("Greater than [#{base}]?",1)
          next if base.to_f > val.to_f
          e.add_attr(set)
          break
        end
      when 'max_base'
        msg "Compare by Maximum Base for [#{val}]"
        d.each_node do |e|
          base=e.text
          msg("Less than [#{base}]?",1)
          next if base.to_f < val.to_f
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
