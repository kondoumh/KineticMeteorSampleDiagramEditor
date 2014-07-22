root = global ? window

if root.Meteor.isClient

  Meteor.startup ->
    kineticContext.build()
    kineticFactory.build()
    graph.build()

    funa = graph.addNode 'ふなっしー'
    hyaha = graph.addNode 'ヒャハー'
    shiru = graph.addNode '梨汁プシャー'
    graph.addEdgeByIds funa, hyaha
    graph.addEdgeByIds funa, shiru

    console.log 'client ready.'

  append = () ->
    graph.addNode $('#form-title').val()
    $('#form-title').val ''

  Template.diagram.greeting = () ->
    'Welcome to dia-study. ' + (->
      d = new Date
      "#{d.getHours()}:#{d.getMinutes()}:#{d.getSeconds()}")()

  Template.diagram.events({
    'click #add-node' : () ->
      append()

    'keypress #form-title' : (event) ->
      if event.charCode == 13
        append()

    'change #edge-mode' : (event) ->
      edgeContext['addingEdge'] = event.target.checked

  })

if root.Meteor.isServer
  Meteor.startup ->
    console.log 'Server started!'
