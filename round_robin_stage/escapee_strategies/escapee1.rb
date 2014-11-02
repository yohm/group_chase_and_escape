require 'pp'

class EscapeeStrategy

  def next_direction(chaser_positions, escapee_positions)
    dx, dy = chaser_positions.first
    candidate = [[1,0],[-1,0],[0,1],[0,-1]]
    if dx > 0
      candidate.delete([1,0])
    elsif dx < 0
      candidate.delete([-1,0])
    end
    if dy > 0
      candidate.delete([0,1])
    elsif dy < 0
      candidate.delete([0,-1])
    end
    candidate.sample
  end
end
