#!/usr/bin/ruby
module ModSym
  def init_sym(tbl={})
    @doc.find_each('symbol','table'){|e1|
      row=e1.to_h
      id=row.delete('id')
      rc=row[:record]={}
      e1.each{|e2| # case
        if e2.text
          rc[e2.text]=e2.to_h
        else
          rc.default=e2.to_h
        end
      }
      tbl[id]=row
    }
    @v.msg{"Table:#{tbl}"}
    tbl
  end
end
