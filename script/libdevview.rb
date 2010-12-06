#!/usr/bin/ruby
class DevView
  attr_reader :tbl

  def initialize(ddb)
    @tbl={}
    ddb['rspselect'].each{|e1|
      e1.each{|e2|
        if e2['assign']
          @tbl[e2['assign']]={:label=>e2['label'],:symbol=>e2['symbol'] }
        end
      }
    }
  end

end
