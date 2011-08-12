#!/usr/bin/ruby
require "libverbose"
class Cache < Hash
  VarDir="#{ENV['HOME']}/.var"
  def initialize(filename,&proc)
    @filename=VarDir+"/"+filename+".mar"
    @proc=proc
    @v=Verbose.new('CACHE',1)
    load
  end

  def load
    hash=Marshal.load(IO.read(@filename))
    raise if hash.empty?
    update hash
  rescue
    refresh
  end

  def save
    open(@filename,'w') {|f|
      @v.msg{"Saving"}
      f << Marshal.dump(Hash[self])
    }
  end

  def refresh
    update(@proc.call)
    save
  end
end
