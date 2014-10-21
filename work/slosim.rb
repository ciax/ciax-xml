#!/usr/bin/ruby
Thread.abort_on_exception=true
$target=0
$pulse=0
Thread.new{
  loop{
    sleep 0.2
    diff=$target-$pulse
    if diff!=0
      $pulse+=diff/diff.abs
      if $pulse > 999
        $pulse-=10000
      elsif $pulse < 0
        $pulse+=10000
      end
    end
  }
}

def sett(n)
  if n > 9999
    $target=9999
  elsif n < 0
    $target=0
  else
    $target=n
  end
end

while a=gets
  b=a.split('=')
  num=(b[1].to_f*10).to_i
  case b[0]
  when 'abspos'
    sett($pulse=num)
  when 'p'
    sett($pulse=num)
  when 'ma'
    sett(num)
  when 'mi'
    sett($target+num)
  when 'stop'
    sett($pulse)
  when /^q/
    break
  else
    puts "%.1f" % ($pulse.to_f/10)
  end
end
