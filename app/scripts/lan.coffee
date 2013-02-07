class EventEmitter
  constructor: ->
    @events = {}
  emit: (event, args...) ->
    return false unless @events[event]
    listener args... for listener in @events[event]
    return true
  addListener: (event, listener) ->
    @emit 'newListener', event, listener
    (@events[event]?=[]).push listener
    return @
  on: @::addListener
  once: (event, listener) ->
    fn = =>
      @removeListener event, fn
      listener arguments...
    @on event, fn
    return @
  removeListener: (event, listener) ->
    return @ unless @events[event]
    @events[event] = (l for l in @events[event] when l isnt listener)
    return @
  removeAllListeners: (event) ->
    delete @events[event]
    return @


class window.Player extends EventEmitter
  constructor: (@name)->
    @cards = []
    @score = 0
    super()
    @on "end", => window.clearTimeout @timer
  startTurn: (time=10000)->
    @timer = window.setTimeout(@end, time)
    @emit "start"
  end: =>
    @emit "end"


class window.Game extends EventEmitter
  constructor: (@players=[])->
    @rounds = [
      'number'
      'letter'
      'letter'
      'number'
      'letter'
      'letter'
    ]
    super()
  start: -> @nextRound()
  nextRound: ->
    @currentRound.removeAllListeners() if @currentRound
    @currentRound = switch @rounds.pop()
      when 'number' then new NumberRound(@players)
      when 'letter' then new LetterRound(@players)
    @emit("newRound", @currentRound) if @currentRound
  winner: ->
    max = -1
    @winner = @players[0]
    for p in @players
      if p.score > max
        @winner = p
        max = p.score
    @winner


class window.Round extends EventEmitter
  constructor: (@players=[]) ->
    @currentPlayer = -1
    super()
  nextPlayer: ->
    @currentPlayer += 1
    @players[@currentPlayer]
  start: ->
    @emit "start"


class window.LetterRound extends Round
  constructor: (@players=[]) ->
    @vowels = ["a","e","i","o","u"]
    @consonants = ["b","c","d","f","g","h","j","k","l","m","n","p","q","r","s","t","v","w","x","y","z"]
    @deck = []
    super(@players)
    @on "end", =>
      max = -1
      @players.forEach (p)=>
        if p.word.score > max
          max = p.word.score
          @winner = p
      # check for others who got the same score
      for p in @players
        if p.word.score == @winner.word.score
          p.score += p.word.score
  type: -> "LetterRound"
  addPlayer: (player)-> @players.push(player)
  buildDeck: (vowelCount=3)->
    for i in [1..vowelCount]
      rnd = Math.floor(Math.random() * @vowels.length)
      @deck.push @vowels[rnd]
    for i in [1..9-vowelCount]
      rnd = Math.floor(Math.random() * @consonants.length)
      @deck.push @consonants[rnd]
  isValidWord: (word)->
    testWord = new Word(word)
    if testWord.valid()
      letters = word.toLowerCase().split ""
      localDeck = [].concat @deck
      for l in letters
        i = localDeck.indexOf(l)
        if i > -1 then localDeck.splice(i,1) else return false
      true
    else
      false


class window.NumberRound extends Round
  constructor: (@players=[]) ->
    @big = [25,50,75,100]
    @small = [1,2,3,4,5,6,7,8,9,10,1,2,3,4,5,6,7,8,9,10]
    @ops = ["+","-","*","/"]
    @goalNumber = Math.floor(Math.random() * 998) + 1
    super(@players)
    @on "end", =>
      @players.forEach (p)=>
        dist = Math.abs(p.equation.total - @goalNumber)
        if dist == 0
          p.score += 10
        else if dist <= 5
          p.score += 7
        else if dist <= 10
          p.score += 5
  type: -> "NumberRound"
  buildDecks: (smallNumberCount, slots=6)->
    cards = []
    for i in [1..smallNumberCount]
      rnd = Math.floor(Math.random() * @small.length)
      cards.push @small[rnd]
      @small.splice(i,1)
    for i in [1..slots-smallNumberCount]
      rnd = Math.floor(Math.random() * @big.length)
      cards.push @big[rnd]
      @big.splice(i,1)
    p.cards = [].concat(cards) for p in @players
    @players.forEach (p)-> p.equation = new MathEquation()
  playCard: (player, card)->
    if @ops.indexOf(card) > -1 then @playOperator(player,card) else @playNumber(player,card)
  playNumber: (player, num)->
    num = parseInt(num)
    if player.cards.indexOf(num) > -1
      player.equation.addCard(num)
      player.cards.splice(player.cards.indexOf(num),1)
      player.emit "cardAdded", num
      true
    else
      false
  playOperator: (player, op)->
    if @ops.indexOf(op) > -1
      player.equation.addCard(op)
      player.emit "cardAdded", op
      true
    else
      false


class window.MathEquation
  constructor: ->
    @cards = []
    @total = 0
    @eq = ""
  addCard: (card)->
    @cards.push card
    @calculate()
  length: -> @cards.length
  needsOperator: -> @length() % 2 == 1
  toString: ->
    out = ""
    out += " #{card} " for card in @cards
    out
  get_total_recursive: (rem, acc)->
    [op, val] = [rem[0], rem[1]]
    switch op
      when "+" then acc += val
      when "-" then acc -= val
      when "*" then acc *= val
      when "/" then acc /= val
    if rem.length > 2 then @get_total_recursive(rem[2..-1], acc) else acc
  calculate: ->
    if @length() > 1 && @length() % 2 == 1
      first = @cards[0]
      rest = @cards[1..-1]
      @total = @get_total_recursive(rest,first)


class window.Word
  constructor: (@value)->
    @score = @getScore()
  getScore: ->
    if @value.length < 9
      @value.length
    else
      @value.length * 2
  valid: ->
    # TODO dictionary lookup
    true
