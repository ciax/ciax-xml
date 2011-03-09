#!/usr/bin/ruby
require "json"


def keylist
  list=[]
  open("/home/ciax/config/sdb_dsi.txt"){|f|
    while line=f.gets
      next unless /.+/ === line
      csv=line.split(',')
      #    warn "#{csv[0]}(#{csv[2]})"
      list << csv[0]
    end
  }
  list
end

stat=JSON.load(gets(nil))
dev="dsi"
res="%#{dev}_#{stat['exe']}0_"
keylist.each{|key|
  res << stat[key]
}
puts res
