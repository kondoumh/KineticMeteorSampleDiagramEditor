@GraphNodes = new Meteor.Collection 'GraphNodes'

@GraphNodes.validate = (graphNode) ->
  if graphNode.title then true else false

@Edges = new Meteor.Collection 'Edges'

root = global ? window

if root.Meteor.isClient

  Meteor.startup ->
    kContext.build()
    graph.build()
    kineticFactory.build()

    funa = graph.addNode 'ふなっしー'
    hyaha = graph.addNode 'ヒャハー'
    shiru = graph.addNode '梨汁プシャー'
    graph.addEdge2 funa, hyaha
    graph.addEdge2 funa, shiru

    console.log 'client ready.'

  Template.diagram.greeting = () ->
    'Welcome to dia-study. ' + (->
      d = new Date
      "#{d.getHours()}:#{d.getMinutes()}:#{d.getSeconds()}")()


  Template.diagram.events({
    'click #add-node' : () ->
      graph.addNode $('#form-title').val()
      $('#form-title').val ''

    'change #edge-mode' : (event) ->
      edgeContext['addingEdge'] = event.target.checked
  })

if root.Meteor.isServer
  Meteor.startup ->
    console.log 'Server started!'
