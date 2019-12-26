#require 'highline/import'
$LOAD_PATH << File.dirname(__FILE__)
require 'about_scoring_project'
require 'about_dice_project'

class Player
  attr_accessor :score

  def initialize(score)
    @score = score
    self
  end
end

class Turn
  attr_accessor :accumulated_score, :player
  attr_reader :player_index

  def initialize(player, player_index)
    @player = player
    @accumulated_score = 0
    @player_index = player_index
    self
  end

  def accumulate(current_score)
    @accumulated_score = (current_score == 0) ? current_score : @accumulated_score + current_score
    return current_score == 0 ? false : true
  end

  def reset_accumulated_score
    @accumulated_score = 0
  end

  def print_scores
    puts "Score in this round:", @accumulated_score
    puts "Total Score:", @player.score + @accumulated_score
  end

  def compute_player_score
    @player.score = @player.score + @accumulated_score
  end

  def initial_minimum_score_unsatisfied?
    if @player.score == 0 and @accumulated_score < 300
      @accumulated_score = 0
      return true
    end
    return false
  end

  def max_score_limit_reached?
    @accumulated_score + @player.score >= 3000
  end

end

class PlayingGreed
  attr_accessor :players

  def initialize
    @players = []
  end

  def play_and_set_score(turn, n)
    dice = DiceSet.new
    dice.roll(n)
    player_index = turn.player_index
    puts "Player #{player_index + 1} rolls: ", dice.values.join(', ')
    current_score = score(dice)
    turn.accumulate(current_score)

    if turn.max_score_limit_reached?
      turn.print_scores
      turn.compute_player_score
      return true
    end

    scored_count = n - unscored_count(dice)

    # Exit if the user scores 0 in current turn
    if current_score == 0
      turn.reset_accumulated_score
      turn.print_scores
      return false
    end

    turn.print_scores

    if n == scored_count
      puts "Do you want to roll the dices again?(y/n):"
      roll_again = gets.chomp
      return play_and_set_score(turn,5) if roll_again.strip.downcase == 'y'
    elsif scored_count > 0 and n == 5
      puts "Do you want to roll the non-scoring #{n - scored_count} dices?(y/n):"
      roll_again = gets.chomp
      return play_and_set_score(turn, n - scored_count) if roll_again.strip.downcase == 'y'
    end

    turn.print_scores if turn.initial_minimum_score_unsatisfied?
    turn.compute_player_score
    return false
  end

  def play
    puts 'Enter number of players:'
    no_of_players = gets.chomp.to_i
    no_of_players.times do
      players << Player.new(0)
    end
    ctr = 0
    final_turn = false
    reached_player = nil
    max_scored_player = nil
    while true
      ctr += 1
      puts "Turn #{ctr}\n----------"
      for i in (0..no_of_players-1) do
        player = players[i]
        turn = Turn.new(player, i)
        final_turn = play_and_set_score(turn, 5)
        if final_turn
          reached_player = i
          max_scored_player = i
          break
        end
      end
      break if final_turn
    end

    puts "------------------\n------------------\n"
    puts "Final turn begins now, all except player #{reached_player + 1} are going to roll dice !!\n"
    puts "------------------\n------------------\n"

    for i in (0..no_of_players-1) do
      next if i == reached_player
      player = players[i]
      turn = Turn.new(player, i)
      play_and_set_score(turn, 5)
      max_scored_player = i if player.score > players[max_scored_player].score
    end
    puts "Player #{max_scored_player + 1} wins !!!, Player #{max_scored_player + 1}'s Score: ", players[max_scored_player].score
  end
end
