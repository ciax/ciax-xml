#!/usr/bin/ruby
require "libxmldoc"
require "libmcrilk"
#require "libobj"
#require "libdev"
require "libmodview"
include ModView
warn "Usage: mcrshell [obj]" if ARGV.size < 1

obj=ARGV.shift || 'crt'
doc=XmlDoc.new('mdb',obj)
mdb=McrIlk.new(doc)
cr=mdb
loop do 
  cr.prompt
  line=gets.chomp
  case line
  when /^q/
    break
  when /^eval/
    eval line.sub(/eval/,'') rescue(puts $!)
  when /[\w]+/
    cr=mdb.setmcr(line)
  else
    view(cr.stat)
  end
  begin
    cr.mcrproceed if cr
  rescue
    puts $!
  end
end
