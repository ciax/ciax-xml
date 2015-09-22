#!/usr/bin/ruby
# IDB,CDB CSV(CIAX-v1) to MDB
#alias c2m
require 'json'
abort "Usage: csv2mdb [sites]" if ARGV.size < 1

def prt_cond(fld)
  fld.split('&').each{|cond|
    attr='form ="msg"'
    if /:/ =~ cond
      attr+=' site="%s"' % $`
      cond=$'
    end
    if /[!=\~]/ =~ cond
      attr+=' var="%s"' % $`
      tag={'~'=>'pattern','!'=>'not','='=>'equal'}[$&]
      puts '   <%s %s>%s</%s>' % [tag,attr,$',tag]
    end
  }
end

def get_file(site,mdb)
  ['idb','cdb'].each{|db|
    open("#{db}_#{site}.txt"){|f|
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
  mdb
end

mdb={}
ARGV.each{|site|
  get_file(site,mdb)
}
print JSON.dump mdb.select{|k,v|
  ['seq','goal','check'].any?{|f| v.key?(f)}
}
