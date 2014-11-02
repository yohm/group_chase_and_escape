require 'pp'

class EscapeeStrategy
  
  def initialize
  end

  def next_direction(chaser_positions, escapee_positions)
    points = { [1,0] => 0.0, [-1,0] => 0.0, [0,1] => 0.0, [0,-1] => 0.0 }
    chaser_positions[0..3].each do |dx,dy|
      r = (dx.abs + dy.abs).to_f
      if dx > 0
        points[ [-1,0] ] += dx.abs/(r*r)
      elsif dx < 0
        points[ [1,0] ] += dx.abs/(r*r)
      end
      if dy > 0
        points[ [0,-1] ] += dy.abs/(r*r)
      elsif dy < 0
        points[ [0,1] ] += dy.abs/(r*r)
      end
    end
    direction = points.max {|a,b| a[1] <=> b[1] }[0]
    direction
  end
end
