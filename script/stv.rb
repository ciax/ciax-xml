#!/usr/bin/ruby
def color(c,msg)
  print "\e[1;3#{c}m#{msg}\e[0m"
end

def prt(stat,c)
  print '['
  color(6,stat['label'])
  print ':'
  if stat['type'] == 'ENUM'
    color(c,stat['msg'])
  else
    color(c,stat['val']+'('+stat['msg']+')')
  end
  puts ']'
end

Marshal.load(gets(nil)).sort.each do |id,stat|
  case stat['hl']
  when 'alarm'
    prt(stat,'1')
  when 'warn'
    prt(stat,'3')
  when 'normal'
    prt(stat,'2')
  when 'hide'
    prt(stat,'2') if ENV['VER']
  end
end
