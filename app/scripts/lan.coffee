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

class window.Player
  constructor: (@name)->
    @cards = []
    @score = 0

class window.Round extends EventEmitter
  constructor: ->
    @players = []
    @currentPlayer = 0
    @turnCount = 0
    super()
  nextPlayer: ->
    if @currentPlayer+1 == @players.length then @currentPlayer = 0 else @currentPlayer += 1
    @players[@currentPlayer]
  start: ->
    @timer = window.setTimeout(@end, 1000)
    @emit "start"
  end: =>
    console.log "Round Over"
    @emit "end"

class window.LetterRound extends Round
  constructor: ->
    @vowels = ["a","e","i","o","u"]
    @consonants = ["b","c","d","f","g","h","j","k","l","m","n","p","q","r","s","t","v","w","x","y","z"]
    @deck = []
    super()
  addPlayer: (player)-> @players.push(player)
  buildDeck: (vowelCount=3)->
    for i in [1..vowelCount]
      rnd = Math.floor(Math.random() * @vowels.length)
      @deck.push @vowels[rnd]
    for i in [1..9-vowelCount]
      rnd = Math.floor(Math.random() * @consonants.length)
      @deck.push @consonants[rnd]

  #turn: ->
    #player = @nextPlayer()
    #@turnCount++
    #if @turnCount == 1
      #console.log "#{player.name}, how many vowels should there be in the set of 9 letters? You may choose 3, 4 or 5"
      #prompt.start()
      #prompt.get(["vowels"], (err, result) =>
        #count = result.vowels
        #@buildDeck(count)
        #@turn()
      #)
    #else if @turnCount == @players.length+2
      #for player in @players
        #console.log "#{player.name}: #{player.word.value} (#{player.word.score} points)"
    #else
      #console.log "#{player.name}, enter the longest word you can make with the following letters:"
      #@printArray(@deck, false)
      #prompt.start()
      #prompt.get(["word"], (err, result) =>
        #player.word = new Word(result.word)
        #@turn()
      #)

class window.NumberRound extends Round
  constructor: ->
    @big = [25,50,75,100]
    @small = [1,2,3,4,5,6,7,8,9,10,1,2,3,4,5,6,7,8,9,10]
    @ops = ["+","-","*","/"]
    @goalNumber = Math.floor(Math.random() * 998) + 1
    super()
  addPlayer: (player)->
    player.equation = new MathEquation()
    @players.push(player)
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
  playNumber: (player, num)->
    num = parseInt(num)
    if player.cards.indexOf(num) > -1
      player.equation.addCard(num)
      player.cards.splice(player.cards.indexOf(num),1)
      true
    else
      false
  playOperator: (player, op)->
    if @ops.indexOf(op) > -1
      player.equation.addCard(op)
      true
    else
      false

  #turn: ->
    #player = @nextPlayer()
    #@turnCount++
    #if @turnCount == 1
      #console.log "#{player.name}, how many small numbers should make up the set of 6 numbers?"
      #prompt.start()
      #prompt.get(["smalls"], (err, result) =>
        #@buildDecks(result.smalls)
        #@turn()
      #)
    #else
      #console.log "--------------------------------------------------===== #{@turnCount} =====--------------------------------------------------"
      #console.log "Your turn, #{player.name}. Try to reach #{@goalNumber}"
      #player.equation.print()
      #if player.equation.length() == 0
        #@printArray(player.cards)
        #prompt.start()
        #prompt.get(["number"], (err, result) =>
          #@playNumber(player,result["number"])
          #@turn()
        #)
      #else
        #@printArray(player.cards)
        #@printArray(@ops)
        #prompt.start()
        #prompt.get(["operation"], (err, result) =>
          #@playOperator(player,result["operation"])
          #prompt.get(["number"], (err, result) =>
            #@playNumber(player,result["number"])
            #player.equation.print()
            #@turn()
          #)
        #)

class window.MathEquation
  constructor: ->
    @cards = []
    @total = 0
    @eq = ""
  addCard: (card)->
    @cards.push card
    @calculate()
  length: -> @cards.length
  calculate: ->
    if @cards.length > 1 && @cards.length % 2 == 1
      @eq = ""
      parensCount = Math.floor(@cards.length/2) - 1
      @eq += "(" for i in [0..parensCount]
      @eq += @cards[0]
      for card,i in @cards[1..-1]
        @eq += card
        @eq += ")" if i % 2 == 1
      @total = eval(@eq)

class Word
  constructor: (@value)->
    @score = @getScore()
  getScore: ->
    if @value.length < 9
      @value.length
    else
      @value.length * 2
