class HTMLGame

  constructor: (@appContainer)->
    @roundNumber = 0
    @grabTemplates()
    @players = []
    @game = null

    @appContainer.delegate(".nextRound", "click", (e)=>
      e.preventDefault()
      @game.nextRound()
    )
    @appContainer.delegate(".startGame", "click", (e)=>
      self = this
      e.preventDefault()
      @appContainer.find("input").each( ->
        me = $(this)
        if me.val() != ""
          p = new Player(me.val())
          self.players.push p
      )
      @game = new Game(@players)
      @setupGame()
      @game.start()
    )

  setupGame: ->
    me = this
    @game.on('newRound', (round)=>

      round.on 'start', =>
        @roundNumber += 1
      round.on 'end', =>
        @resetTimerAnimation()
        if @game.rounds.length == 0
          @renderTemplate('gameOver', winner: @game.winner().name, players: @players)
        else
          @renderTemplate('roundRecap', roundNumber: @roundNumber, players: @players)

      if round.type() == "LetterRound"
        vowels = @prompt("How many vowels should there be in the set of 9 letters? You may choose 3, 4 or 5.", [3,4,5])
        round.buildDeck(vowels)
        doLetterTurn = =>
          if @currentPlayer
            word = @appContainer.find(".word").val()
            @currentPlayer.word = new Word(word)
          @currentPlayer = round.nextPlayer()
          if @currentPlayer?
            @clearScreen()
            alert("#{@currentPlayer.name} is up.")
            @currentPlayer.removeAllListeners()
            @currentPlayer.once "end", => doLetterTurn()
            @renderTemplate 'letterRoundTurn', name: @currentPlayer.name, deck: round.deck
            @appContainer.find(".submitWord").click (e)=>
              e.preventDefault()
              @currentPlayer.emit "end"

            @appContainer.find('.word').keyup (e)=>
              $(e.target).removeClass 'invalid'
              word = $(e.target).val()
              letters = word.split("")
              $(e.target).addClass('invalid') unless round.isValidWord(word)
              @appContainer.find('.card').removeClass('disabled')
              for l in letters
                @appContainer
                  .find('.card[data-value="'+l.toLowerCase()+'"]')
                  .not('.disabled')
                  .first()
                  .addClass('disabled')

            @currentPlayer.startTurn(35000)
            @startTimerAnimation()
          else
            round.emit "end"
        doLetterTurn()

      else # NumberRound
        smalls = @prompt("How many small numbers should make up the set of 6 numbers?", [1,2,3,4,5,6])
        round.buildDecks(smalls)
        doNumberTurn = =>
          @currentPlayer = round.nextPlayer()
          if @currentPlayer?
            @clearScreen()
            alert("#{@currentPlayer.name} is up.")
            @currentPlayer.removeAllListeners()
            @currentPlayer.once "end", => doNumberTurn()

            doNumberMove = =>
              @renderTemplate 'numberRoundTurn',
                name: @currentPlayer.name,
                deck: @currentPlayer.cards,
                ops: round.ops,
                equation: @currentPlayer.equation.toString(),
                total: @currentPlayer.equation.total,
                goal: round.goalNumber
              if @currentPlayer.equation.needsOperator()
                @appContainer.find('a.card.number').addClass('disabled')
              else
                @appContainer.find('a.card.operator').addClass('disabled')
              @appContainer.find('a.card.number').not('.disabled').click (e)->
                e.preventDefault()
                round.playNumber me.currentPlayer, $(this).data('value')
              @appContainer.find('a.card.operator').not('.disabled').click (e)->
                e.preventDefault()
                round.playOperator me.currentPlayer, $(this).data('value')
              @appContainer.find('a.card').click (e)->
                e.preventDefault()
                doNumberMove()
              @appContainer.find(".submitEquation").click (e)=>
                e.preventDefault()
                @currentPlayer.emit "end"
            doNumberMove()
            @currentPlayer.startTurn(35000)
            @startTimerAnimation()
          else
            round.emit "end"
        doNumberTurn()

      round.start()
    )

  grabTemplates: ->
    @templates = {}
    me = this
    $('.jqtemplate').each( ->
      me.templates[$(this).attr('id')] = $(this)
    )

  renderTemplate: (templateName, data=null)->
    @appContainer.html(@templates[templateName].tmpl(data))
      .find('input, button').first().focus()

  clearScreen: ->
    @resetTimerAnimation()
    @appContainer.html("")

  resetTimerAnimation: ->
    $('.timer').html("")

  startTimerAnimation: ->
    $('.timer').html("<div class='bar' />").find('.bar').width("100%").css("background", "#f00")

  prompt: (message, allowed=null) ->
    answer = window.prompt(message)
    if allowed? and allowed.indexOf(parseInt(answer)) == -1
      @prompt message, allowed
    else
      answer

  start: ->
    @renderTemplate 'newGame'



$ ->
  app = $("#app")
  game = new HTMLGame(app)
  game.start()
