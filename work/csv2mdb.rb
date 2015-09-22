#!/usr/bin/ruby
# IDB,CDB CSV(CIAX-v1) to MDB
#alias c2m
require 'json'
abort "Usage: csv2mdb [sites]" if ARGV.size < 1

mdb={}
ARGV.each{|site|
  ['idb','cdb'].each{|db|
    open(ENV['HOME']+"/config/#{db}_#{site}.txt"){|f|
      f.readlines.each{|line|
        next if /^[a-zA-Z0-9]/ !~ line
        id,goal,check,type,seq=line.chomp.split(',')
        next if type == 'cap'
        case site
        when /mcr/
          con=(mdb[id]||={})
          case type
          when 'mcr'
            con['title']=goal
            con['seq']=seq.split(" ") if seq and !seq.empty?
          else
            con['goal']=goal.split("&") if goal and !goal.empty?
            con['check']=check.split("&") if check and !check.empty?
          end            
        else
          con=(mdb["#{site}_#{id}"]||={})
          case type
          when 'act','cmd'
            con['title']=goal
            con['exe']=["#{site}:#{id}"]
          else
            con['goal']=goal.split("&") if goal and !goal.empty?
            con['check']=check.split("&") if check and !check.empty?
          end
        end
      }
    }
  }
}
print JSON.dump mdb.select{|k,v|
  ['seq','goal','check'].any?{|f| v.key?(f)}
}
