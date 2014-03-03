@GraphNodes = new Meteor.Collection 'GraphNodes'

@GraphNodes.validate = (graphNode) ->
  if graphNode.title then true else false

colorByName = (name) ->
  if name.length % 5 == 0
    'green'
  else if name.length % 3 == 0
    'red'
  else if name.length % 2 == 0
    'pink'
  else
    'yellow'

buildContext = (context) ->
  context.stage = new Kinetic.Stage({
    container  : container
    width      : 578
    height     : 200
  })
  context.layer = new Kinetic.Layer()
  context.stage.add context.layer
  context.getRandomX = () ->
    parseInt Math.random()*(context.stage.getWidth() - 100)
  context.getRandomY = () ->
    parseInt Math.random()*(context.stage.getHeight() - 50)
  context.registerShape = (label) ->
    context.layer.add label
    addTweenEffect label.getTag()
    addTweenEffect label.getText()
    context.layer.draw()

createShape = (graphNode, id) ->
  label = new Kinetic.Label({
    x: graphNode.xpos
    y: graphNode.ypos
    width: 100
    height: 50
    draggable: true
    id: id
    name: graphNode.title
  })
  .on 'dragmove', () ->
    GraphNodes.update {_id: this.getId()}, { $set: xpos: this.attrs.x, ypos: this.attrs.y}
    entry = GraphNodes.findOne _id: this.getId()
    if entry
      console.log entry.title + ' ' + entry.xpos + ',' + entry.ypos
  .on 'mouseover', () ->
    document.body.style.cursor = 'pointer'
    this.getTag().tween.play()
    this.getText().tween.play()
  .on 'mouseout', () ->
    document.body.style.cursor = 'default'
    this.getTag().tween.reverse()
    this.getText().tween.reverse()

  label.add new Kinetic.Tag({
    fill: colorByName(graphNode.title)
    stroke: 'black'
    strokeWidth: 4
  })

  label.add new Kinetic.Text({
    text: graphNode.title
    fontSize: 18
    padding: 10
    fill: 'black'
  })
  label


addTweenEffect = (node) ->
  node.tween = new Kinetic.Tween({
    node: node
    scaleX: 1.2
    scaleY: 1.2
    easing: Kinetic.Easings.EaseInOut
    duration: 0.5
  })


root = global ? window

if root.Meteor.isClient
  context = {}

  Meteor.startup ->
    buildContext context
    console.log 'client ready.'

  Template.diagram.greeting = () ->
    'Welcome to dia-study.'

  Template.diagram.events = 'click button' : () ->
    graphNode =
      title: $('#form-title').val()
      xpos : context.getRandomX()
      ypos : context.getRandomY()

    if not GraphNodes.validate graphNode
      alert 'input invalid'
      return
    inserted = GraphNodes.insert graphNode, (error, result) ->
      if error
        console.log JSON.stringify error, null, 2
      else
        context.registerShape createShape(graphNode, result)
        $('#form-title').val ''


if root.Meteor.isServer
  Meteor.startup ->
    console.log 'Server started!'
