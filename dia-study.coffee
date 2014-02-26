root = global ? window



if Meteor.isClient
  Template.diagram.greeting = () ->
    return "Welcome to dia-study."

  Template.diagram.events = 'click input' : () ->
    console.log("You pressed the button");

if root.Meteor.isServer
  Meteor.startup ->
    console.log "Server started!"

