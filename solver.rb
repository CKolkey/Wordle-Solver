# frozen_string_literal: true

class English
  def self.frequencies
    {
      'E': 56.88, 'A': 43.31, 'R': 38.64, 'I': 38.45, 'O': 36.51, 'T': 35.43,
      'N': 33.92, 'S': 29.23, 'L': 27.98, 'C': 23.13, 'U': 18.51, 'D': 17.25,
      'P': 16.14, 'M': 15.3,  'H': 15.3,  'G': 12.5,  'B': 10.5,  'F': 9.24,
      'Y': 9.06,  'W': 6.57,  'K': 5.61,  'V': 5.13,  'X': 1.48,  'Z': 1.39,
      'J': 1.00,  'Q': 1.00
    }
  end

  def self.words
    File.read('en_wordle').split.map(&:upcase)
  end
end

class Possibilities
  attr_reader :wordlist, :exclude, :placed, :unplaced

  def initialize(language)
    @wordlist    = language.words
    @frequencies = language.frequencies

    # Letters not in the word
    @exclude  = []

    # Letters in the correct place in the word
    @placed   = { 0 => nil, 1 => nil, 2 => nil, 3 => nil, 4 => nil }

    # Letters in the word, but NOT in this place
    @unplaced = { 0 => [], 1 => [], 2 => [], 3 => [], 4 => [] }
  end

  def count = wordlist.count

  def top_guesses
    wordlist.map { |word| [word.chars.uniq.sum { @frequencies[_1.upcase.to_sym] || 0 }, word] }
            .max(10)
            .map { " - \"#{_2}\" (Score: #{_1.round(2)})" }
  end

  def include_letter!(letter, position)
    letter = letter.upcase

    @unplaced[position].push(letter)
    wordlist.select! { _1.chars.include?(letter) && _1[position] != letter }
  end

  def exclude_letter!(letter)
    letter = letter.upcase

    @exclude.push(letter)
    wordlist.reject! { _1.chars.include?(letter) }
  end

  def place_letter!(letter, position)
    letter = letter.upcase

    @placed[position] = letter
    wordlist.select! { _1[position] == letter }
  end

  def excluded?
    exclude.any?
  end

  def print_excluded
    exclude.uniq.sort.join(', ')
  end

  def unplaced?
    unplaced.values.reject(&:empty?).any?
  end

  def print_unplaced
    # unplaced.map { "#{_1 + 1}: \"#{_2.join('", "')}\"" }.join("\n")
    unplaced.values.flatten.uniq.sort.join(', ')
  end

  def placed?
    placed.values.compact.any?
  end

  def print_placed
    placed.map { _2 || '_' }.join(' ')
  end
end

class Prompt
  def initialize(language)
    @possibilities = Possibilities.new(language)
    @count         = 0
  end

  def call
    choose_action
  end

  private

  def choose_action
    clear!

    if @count.positive?
      puts 'Top Guesses:'
      puts @possibilities.top_guesses
      puts ''
    end

    if @possibilities.excluded?
      puts 'Excluded:'
      puts @possibilities.print_excluded
      puts ''
    end

    if @possibilities.unplaced?
      puts 'Included:'
      puts @possibilities.print_unplaced
      puts ''
    end

    if @possibilities.placed?
      puts 'Placed:'
      puts @possibilities.print_placed
      puts ''
    end

    puts "Current Possibilities: #{@possibilities.count}\n\n"
    enter_guess

    @count += 1
  end

  def enter_guess
    guess = get_input('Enter Guess').chars
    puts ''
    puts '(x = Exclude, i = Include, c = Correct)'
    marks = get_input('Mark Guess').chars

    guess.zip(marks).each_with_index do |(letter, mark), position|
      case mark
      when 'x'
        @possibilities.exclude_letter!(letter)
      when 'i'
        @possibilities.include_letter!(letter, position)
      when 'c'
        @possibilities.place_letter!(letter, position)
      end
    end
  end

  protected

  def clear! = puts(`clear`)

  def get_input(text)
    puts text
    print '> '

    gets.chomp
  end
end

prompt = Prompt.new(English)

loop do
  prompt.call
rescue Interrupt, NoMethodError
  puts(`clear`)
  exit
end
