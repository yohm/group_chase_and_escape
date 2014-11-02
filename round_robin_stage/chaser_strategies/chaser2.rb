require 'pp'

class ChaserStrategy

  def initialize
  end

  def next_direction(chaser_positions, escapee_positions)
    candidate = []
    return [0,0] if escapee_positions.empty?
    dx, dy = escapee_positions.first
    r = 5.0 / (dx.abs + dy.abs)
    if rand < r
      if dx > 0
        candidate.push [1,0]
      elsif dx < 0
        candidate.push [-1,0]
      end
      if dy > 0
        candidate.push [0,1]
      elsif dy < 0
        candidate.push [0,-1]
      end
    else
      candidate = [[1,0],[-1,0],[0,1],[0,-1]]
    end
    candidate.sample
  end
end
