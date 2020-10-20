module Sudoku

GRID_SIZE = 9

  class Grid
    attr_accessor :elements
    attr_accessor :givens_indexes
    attr_accessor :score
    attr_accessor :row_scores
    attr_accessor :col_scores

    def initialize(puzzle)
      @elements = []
      @givens_indexes = []
      @score = 0
      @row_scores = []
      @col_scores = []
      populate(puzzle)
    end
    
    def complete_blanks
      (0..8).each do |index|
        box_values = get_box(index)
        missing_values = [*1..9] - box_values
        missing_values.shuffle!
        box_values.each_with_index do |element, index|
          box_values[index] = missing_values.pop if element == 0
        end
        box_indicies = get_box_indicies(index)
        box_values.each_with_index do |value, index|
          @elements[box_indicies[index]] = value
        end
      end
      score_grid
    end

    def score_grid
      @row_scores = []
      @col_scores = []
      @score = 0
      (0..8).each do |index|
        @row_scores << GRID_SIZE - get_row(index).uniq.length
        @col_scores << GRID_SIZE - get_col(index).uniq.length
      end
      update_score
    end

    def update_score
      @score =  0
      @score += @row_scores.reduce(0, :+)
      @score += @col_scores.reduce(0, :+)
      @score
    end

    def create_neighbor
      box = rand(0..8)
      available_indexes = get_box_indicies(box) - @givens_indexes
      swaps = available_indexes.sample(2)
      # swap the elements
      @elements[swaps[0]], @elements[swaps[1]] = @elements[swaps[1]],@elements[swaps[0]]
      # => calculate the new score
      neighbor_score(swaps)
      @elements
    end

    def to_s
      grid = ""
      @elements.each_with_index do |element, index|
        # => look at using group_by on array
        grid += "|" if index % 9 == 0
        element == 0 ? grid += "-" : grid += element.to_s
        grid += "|" if (index + 1) % 3  == 0
        grid += "\n" if (index + 1) % 9 == 0
        grid += "|-----------|\n" if (index + 1) % 27 == 0
      end
      grid
    end

    private

    def get_row(i)
      start_el = i * GRID_SIZE
      end_el = start_el + (GRID_SIZE - 1)
      @elements[start_el..end_el]
    end

    def get_col(i)
      values = []
      (0..8).each do |offset|
        values << @elements[(offset * GRID_SIZE) + i]
      end
      values
    end

    def get_box(i)
      values = []
      (0..2).each do |row_offset|
        box_start = (row_offset * GRID_SIZE) + (i * 3) + ((i / 3) * 18)
        values << @elements[box_start..(box_start + 2)]
      end
      values.flatten
    end

    def neighbor_score(swaps)
      first_swap_row = get_row_index(swaps[0])
      first_swap_col = get_col_index(swaps[0])
      second_swap_row = get_row_index(swaps[1])
      second_swap_col = get_col_index(swaps[1])
      # calculate and update costs of those rows/cols
      @row_scores[first_swap_row] = GRID_SIZE - get_row(first_swap_row).uniq.length
      @row_scores[second_swap_row] = GRID_SIZE - get_row(second_swap_row).uniq.length
      @col_scores[first_swap_col] = GRID_SIZE - get_col(first_swap_col).uniq.length
      @col_scores[second_swap_col] = GRID_SIZE - get_col(second_swap_col).uniq.length
      update_score
    end

    def get_row_index(index)
      index / 9
    end

    def get_col_index(index)
      index % 9
    end

    def get_box_indicies(box)
      indicies = []
      (0..2).each do |row_offset|
        box_start = (row_offset * GRID_SIZE) + (box * 3) + ((box / 3) * 18)
        indicies << [*box_start..(box_start + 2)]
      end
      indicies.flatten!
    end

    def populate(puzzle)
      # convert to int array
      @elements = puzzle.split(//).map(&:to_i)
      # loop over and add any non zero index to givens
      @elements.each_with_index do |element, index|
        if element != 0
          @givens_indexes << index
        end
      end
    end
  end

  class Puzzle

    def initialize(puzzle)
      @grid = Grid.new(puzzle)
    end

    def to_s
      @grid.to_s
    end

    def first_guess
      @grid.complete_blanks
    end

    def score
      @grid.score
    end

    def solve(starting_temp, temp_change)
      # record the best current solution and set temperature
      best_grid = @grid.elements.clone
      best_score = @grid.score
      temp = starting_temp
      non_improving_moves = 0
      iteration = 0
      while true
        iteration += 1
        # create a neighbour
        current_grid = @grid.elements.clone
        current_score = @grid.score
        current_row_score = @grid.row_scores.clone
        current_col_score = @grid.col_scores.clone
        @grid.elements = @grid.create_neighbor
        candidate_score = @grid.score
        # update temperature
        temp *= temp_change
        # ? accept neighbour
        if reject?(current_score, candidate_score, temp)
          @grid.elements = current_grid
          @grid.row_scores = current_row_score
          @grid.col_scores = current_col_score
          @grid.score = @grid.update_score
        end
        # update best if needed
        if candidate_score < best_score
          best_grid = @grid.elements.clone
          best_score = candidate_score
          break if best_score == 0
          non_improving_moves = 0
        else
          non_improving_moves += 1
        end
        if non_improving_moves == 3000
          temp = 2
          non_improving_moves = 0
        end
      end
      puts "interation: #{iteration}"
        #update current grid to be best
        @grid.elements = best_grid
        @grid.score = best_score
    end

    private

    def reject?(current_score, candidate_score, temp)
      Math.exp((current_score - candidate_score) / temp) < rand()
    end
  end
end

MAX_TEMP = 1000.0
TEMP_CHANGE = 0.98

File.open('sample_problems.txt').each_with_index do |puzzle, number|
  puts "------- puzzle: #{number} --------"
  puzzle.strip!
  sudoku = Sudoku::Puzzle.new(puzzle)

  puts sudoku

  sudoku.first_guess

  puts "Current grid score: #{sudoku.score}"

  sudoku.solve(MAX_TEMP, TEMP_CHANGE)
  puts "Done. Current grid score: #{sudoku.score}"
  puts "Grid solution:"
  puts sudoku
end
