root = global ? window

@GraphNodes = new Meteor.Collection("GraphNodes")

@GraphNodes.validate = (graphNode) ->
  if not graphNode.title
    return false
  return true

if root.Meteor.isClient
  Meteor.startup ->
    console.log 'client ready.'

  Template.diagram.greeting = () ->
    return "Welcome to dia-study."

  Template.diagram.events = 'click button' : () ->
    graphNode =
      title: $("#form-title").val()
      xpos: 100
      ypos:100

    if not GraphNodes.validate graphNode
      alert 'input invalid'
      return
    inserted = GraphNodes.insert graphNode
    console.log 'inserted ' + inserted
    $("#form-title").val("")

if root.Meteor.isServer
  Meteor.startup ->
    console.log "Server started!"
