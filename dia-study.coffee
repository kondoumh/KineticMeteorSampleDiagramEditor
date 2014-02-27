root = global ? window

@GraphNodes = new Meteor.Collection("GraphNodes")

@GraphNodes.validate = (graphNode) ->
  if not graphNode.title
    return false
  return true

if root.Meteor.isClient
  context = {}

  Meteor.startup ->
    console.log 'client ready.'
    context.stage = new Kinetic.Stage({
      container  : container
      width      : 578
      height     : 200
    })
    context.layer = new Kinetic.Layer()
    context.stage.add(context.layer)

  Template.diagram.greeting = () ->
    return "Welcome to dia-study."

  Template.diagram.events = 'click button' : () ->
    graphNode =
      title: $("#form-title").val()
      xpos : parseInt Math.random()*(context.stage.getWidth() - 100)
      ypos : parseInt Math.random()*(context.stage.getHeight() - 50)

    if not GraphNodes.validate graphNode
      alert 'input invalid'
      return
    inserted = GraphNodes.insert graphNode, (error, result) ->
      if error
        console.log JSON.stringify error, null, 2
      else
        fill = "yellow"
        if graphNode.title.length % 2 == 0
          fill = "green"
        else if graphNode.title.length % 3 == 0
          fill = "red"
        else if graphNode.title.length % 5 == 0
          fill = "pink"
        $("#form-title").val("")
        rect = new Kinetic.Rect({
          x: graphNode.xpos
          y: graphNode.ypos
          width: 100
          height: 50
          fill: fill
          stroke: "black"
          strokeWidth: 4
          draggable: true
          id: result
          name: graphNode.title
        })
        rect.on "dragmove", () ->
          GraphNodes.update {_id: this.getId()}, { $set: xpos: this.attrs.x, ypos: this.attrs.y}
          entry = GraphNodes.findOne _id: rect.getId()
          if entry
            console.log entry.title + ' ' + entry.xpos + ',' + entry.ypos
        context.layer.add(rect)
        context.layer.draw()

if root.Meteor.isServer
  Meteor.startup ->
    console.log "Server started!"
