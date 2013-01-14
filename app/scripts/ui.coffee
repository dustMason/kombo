$ ->

  app = $("#app")
  app.html($("#newGame").tmpl())

  app.delegate("#start-game", "click", (e)->
    e.preventDefault()
    game = new NumberRound()
    app.data("game", game)
    app.find("input").each( ->
      me = $(this)
      if me.val() != ""
        p = new Player(me.val())
        game.addPlayer p
    )
    
    #game.start()
  )

