#!/usr/bin/ruby
# XML Common Method
require 'librerange'
require 'libverbose'
class Var < Hash
  attr_accessor :stat

  def initialize
    @v=Verbose.new
    @stat={}
  end

  def setstm(stm)
    stm.each_with_index{|s,n| self[n.to_s]=s }
  end

  def sub_var(str)
    return str unless /\$/ === str
    @v.msg(1){"Substitute from [#{str}]"}
    begin
      # Sub $key => self[key]
      str=str.gsub(/\$([\w]+)/){ self[$1] }
      # Sub ${key1:key2:idx} => hash[key1][key2][idx]
      # output csv if array
      str=str.gsub(/\$\{(.+)\}/) {
        [*acc_array($1,@stat)].join(',')
      }
      raise if str == ''
      str
    ensure
      @v.msg(-1){"Substitute to [#{str}]"}
    end
  end

  def acc_stat(key)
    acc_array(key,@stat)
  end

  def acc_array(key,h)
    return h unless key
    key.split(':').each {|i|
      @v.msg{"Var:Type[#{h.class}] Name[#{i}]"}
      i=eval(i) if Array === h
      h=h[i]||raise("No such Value [#{i}]")
    }
    h
  end
end
