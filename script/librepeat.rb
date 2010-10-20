#!/usr/bin/ruby
require 'libverbose'
class Repeat < Hash
  def initialize
    @v=Verbose.new("Repeat")
  end

  def repeat(e)
    a=e.attributes
    fmt=a['format'] || '%d'
    c=a['counter'] || '_'
    c.next! while self[c]
    @v.msg(1){"Counter[\$#{c}]/Range[#{a['from']}-#{a['to']}]/Format[#{fmt}]"}
    begin
      Range.new(a['from'],a['to']).each { |n|
        self[c]=fmt % n
        e.each_element { |d| yield d}
      }
      self.delete(c)
    ensure
      @v.msg(-1){"End"}
    end
  end

  def sub_index(str)
    return str unless /\$[\w]+/ === str
    @v.msg(1){"Substitute from [#{str}]"}
    begin
      # Sub $key => self[key]
      str=str.gsub(/\$([\w]+)/){ self[$1] }
      raise if str == ''
      str
    ensure
      @v.msg(-1){"Substitute to [#{str}]"}
    end
  end
end
