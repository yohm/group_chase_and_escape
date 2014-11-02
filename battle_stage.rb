require 'stringio'
require 'pp'
require 'pry'

require File.join(File.dirname(__FILE__), "chaser_strategy")
require File.join(File.dirname(__FILE__), "escapee_strategy")

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
    $app.stroke(0)
    $app.fill(*self.class::COLOR)
    $app.ellipse(x,y,rx,ry)
  end
end

class Chaser < Player

  COLOR = [255,0,0]

  def initialize(pos)
    super
    @strategy = ChaserStrategy.new
  end

  def next_direction(chaser_positions, escapee_positions)
    @strategy.next_direction(chaser_positions, escapee_positions)
  end
end

class Escapee < Player

  COLOR = [0,255,0]

  def initialize(pos)
    super
    @strategy = EscapeeStrategy.new
  end

  def next_direction(chaser_positions, escapee_positions)
    @strategy.next_direction(chaser_positions, escapee_positions)
  end
end

class BattleStage

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
      validate_direction(direction)
      new_pos = new_position(c.position, direction)
      next if direction == [0,0] or find_player_at(new_pos)
      c.move_to(new_pos)
      handle_catch(c)
      break if @escapees.empty?
    end
  end

  def update_escapees
    @escapees.delete_if do |e|
      chaser_positions, escapee_positions = relative_player_positions_from(e)
      direction = e.next_direction(chaser_positions, escapee_positions)
      validate_direction(direction)
      new_pos = new_position(e.position, direction)
      next if direction == [0,0] or find_player_at(new_pos)
      e.move_to(new_pos)
      collect_neighboring_players_around(e.position).find {|player| player.is_a?(Chaser) }
    end
  end

  def validate_direction(direction)
    raise "#{direction} is not valid" unless direction[0].abs + direction[1].abs <= 1
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

if __FILE__ == $0
  require 'optparse'
  SYSTEM_SIZE = 50
  num_chasers = 5
  num_escapees = 10
  max_timestep = 3000

  opts = OptionParser.new
  opts.on("-c CHASER_SCRIPT") {|script| load script }
  opts.on("-e ESCAPEE_SCRIPT") {|script| load script }
  opts.on("-r RAND_SEED") {|seed| srand(seed.to_i) }
  opts.parse!(ARGV)
  stage = BattleStage.new(SYSTEM_SIZE, SYSTEM_SIZE, num_chasers, num_escapees)

  until stage.finished? or stage.timestep >= max_timestep
    stage.update
    $stderr.puts "#{stage.timestep} #{stage.num_escapees}" if stage.timestep % 10 == 0
  end
  $stdout.puts "Time for total-catch : #{stage.timestep}"
end

