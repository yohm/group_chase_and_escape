require 'stringio'
require 'pp'
require 'pry'

class Player

  attr_reader :position

  def initialize(pos)
    @position = pos
  end

  def move_to(new_pos)
    @position = new_pos
  end

  def display(rx,ry)
    x = @position[0] * rx + rx/2
    y = @position[1] * ry + ry/2
    stroke(0)
    fill(*self.class::COLOR)
    ellipse(x,y,rx,ry)
  end
end

class Chaser < Player

  COLOR = [255,0,0]

  def next_direction(close_chasers, close_escapees)
    dx, dy = close_escapees.first
    candidate = []
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
    candidate.sample
  end

  def next_direction(close_chasers, close_escapees)
    candidate = []
    dx, dy = close_escapees.first
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

class Escapee < Player

  COLOR = [0,255,0]

  def next_direction(close_chasers, close_escapees)
    dx, dy = close_chasers.first
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

  def next_direction(close_chasers, close_escapees)
    points = { [1,0] => 0.0, [-1,0] => 0.0, [0,1] => 0.0, [0,-1] => 0.0 }
    close_chasers[0..3].each do |dx,dy|
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

class Stage

  attr_reader :timestep

  def initialize(lx, ly, num_chaser, num_escapees)
    @lx, @ly = lx, ly
    @chasers = []
    @escapees = []
    @chasers = Array.new(num_chaser) { Chaser.new(random_unique_position) }
    @escapees = Array.new(num_escapees) { Escapee.new(random_unique_position) }
    @timestep = 0
  end

  def update
    update_escapees
    update_chasers
    @timestep += 1
  end

  def to_s
    str = ''
    @ly.times do |y|
      @lx.times do |x|
        player = find_player_at([x,y])
        str += case player
          when Chaser
            'c'
          when Escapee
            'e'
          else
            '_'
          end
      end
      str += "\n"
    end
    str
  end

  def display(width, height)
    rx = width / @lx
    ry = height / @ly
    @chasers.each {|c| c.display(rx,ry) }
    @escapees.each {|e| e.display(rx,ry) }
  end

  def num_escapees
    @escapees.size
  end

  def finished?
    @escapees.empty?
  end

  private
  def find_player_at(pos)
    @chasers.find {|c| c.position == pos } or @escapees.find {|e| e.position == pos }
  end
 
  def random_unique_position
    pos = [rand(@lx), rand(@ly)]
    while find_player_at(pos)
      pos = [rand(@lx), rand(@ly)]
    end
    pos
  end

  def update_chasers
    @chasers.each do |c|
      chaser_positions, escapee_positions = relative_player_positions_from(c)
      direction = c.next_direction(chaser_positions, escapee_positions)
      new_pos = new_position(c.position, direction)
      next if direction == [0,0] or find_player_at(new_pos)
      c.move_to(new_pos)
      handle_catch(c)
      return if @escapees.empty?
    end
  end

  def update_escapees
    @escapees.delete_if do |e|
      chaser_positions, escapee_positions = relative_player_positions_from(e)
      direction = e.next_direction(chaser_positions, escapee_positions)
      new_pos = new_position(e.position, direction)
      next if direction == [0,0] or find_player_at(new_pos)
      e.move_to(new_pos)
      collect_neighboring_players_around(e.position).find {|player| player.is_a?(Chaser) }
      return if @escapees.empty?
    end
  end

  def handle_catch(player)
    if player.is_a?(Chaser)
      neighbors = collect_neighboring_players_around(player.position)
      @escapees -= neighbors
    end
    if player.is_a?(Escapee)
      neighbors = collect_neighboring_players_around(player.position)
      if neighbors.find {|neighbor| neighbor.is_a?(Chaser)}
        @escapees.delete(player)
      end
    end
  end

  def relative_player_positions_from(player)
    chaser_pos = @chasers.reject {|c|
      c == player
    }.map {|c|
      relative_position(c.position, player.position)
    }.sort_by {|dx,dy| dx.abs + dy.abs }
    escapee_pos = @escapees.reject {|e|
      e == player
    }.map {|e|
      relative_position(e.position, player.position)
    }.sort_by {|dx,dy| dx.abs + dy.abs }
    [chaser_pos, escapee_pos]
  end

  def relative_position(pos1, pos2)
    dx = pos1[0] - pos2[0]
    if dx > @lx/2
      dx -= @lx
    elsif dx < -@lx/2
      dx += @lx
    end
    dy = pos1[1] - pos2[1]
    if dy > @ly/2
      dy -= @ly
    elsif dy < -@ly/2
      dy += @ly
    end
    [dx, dy]
  end

  def new_position(old_position, direction)
    new_x = old_position[0] + direction[0]
    if new_x < 0
      new_x += @lx
    elsif new_x >= @lx
      new_x -= @lx
    end
    new_y = old_position[1] + direction[1]
    if new_y < 0
      new_y += @ly
    elsif new_y >= @ly
      new_y -= @ly
    end
    [new_x, new_y]
  end

  def collect_neighboring_players_around(position)
    [[1,0], [-1,0], [0,1], [0,-1]].map do |dr|
      find_player_at( new_position(position, dr) )
    end.compact
  end
end

def setup
  size(700,500)
  srand(ARGV[0].to_i) if ARGV[0]
  @system_size = 50
  @total_num_escapees = 10
  @stage = Stage.new(@system_size,@system_size,5,@total_num_escapees)
  frame_rate(20)
  text_size(32)
  text_align(RIGHT)
end

def draw
  background(0)
  @stage.update unless @stage.finished?
  @stage.display(500,500)
  draw_sidebar
end

def draw_sidebar
  fill(255)
  rect(500,0,200,500)
  fill(192,64,64)
  text("Prize:\n #{@stage.timestep}00 Yen", 680, 40)
  fill(0,128,64)
  text_align(RIGHT)
  text("#{@stage.num_escapees} / #{@total_num_escapees}", 680, 480)
  @total_num_escapees.times do |i|
    fill(128) if @stage.num_escapees == i
    rect(640,400-30*i,30,30,2)
  end
end
