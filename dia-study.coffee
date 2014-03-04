@GraphNodes = new Meteor.Collection 'GraphNodes'

@GraphNodes.validate = (graphNode) ->
  if graphNode.title then true else false

EdgeAddingStatus =
  nothing: 0
  started: 1
  end:     2

@edgeContext =
  addingEdge: false
  status: EdgeAddingStatus.nothing
  startx: 0
  starty: 0
  endx: 0
  endy: 0
  from: ''
  to: ''

colorByName = (name) ->
  if name.length % 5 is 0
    'green'
  else if name.length % 3 is 0
    'red'
  else if name.length % 2 is 0
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
  .on 'mouseup', (event) ->
    if not edgeContext.addingEdge
      console.log 'bye'
      return
    if edgeContext.status is EdgeAddingStatus.nothing
      edgeContext['status'] = EdgeAddingStatus.started
      edgeContext['startx'] = event.screenX
      edgeContext['starty'] = event.screenY
      console.log edgeContext.startx + ' ' + edgeContext.status
      console.log 'from ' + edgeContext.from
      return
    if edgeContext.status is EdgeAddingStatus.started
      edgeContext['status'] = EdgeAddingStatus.end
      edgeContext['endx'] = event.screenX
      edgeContext['endy'] = event.screenY
      console.log edgeContext.endx + ' ' + edgeContext.status
      console.log 'from ' + edgeContext.from + ' to ' + edgeContext.to
      edgeContext['status'] = EdgeAddingStatus.nothing
      console.log 'ready'
      if edgeContext.from is edgeContext.to
        return
      console.log 'go'

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
    GraphNodes.update {_id: @getId()}, { $set: xpos: @attrs.x, ypos: @attrs.y}
    entry = GraphNodes.findOne _id: @getId()
    if entry
      console.log entry.title + ' ' + entry.xpos + ',' + entry.ypos
  .on 'mouseover', () ->
    document.body.style.cursor = 'pointer'
    @getTag().tween.play()
    @getText().tween.play()
  .on 'mouseout', () ->
    document.body.style.cursor = 'default'
    @getTag().tween.reverse()
    @getText().tween.reverse()
  .on 'mouseup', () ->
    console.log 'mouseup on label'
    if edgeContext.addingEdge
      if edgeContext.status is EdgeAddingStatus.nothing
        console.log 'aaa ' + edgeContext.status
        edgeContext['from'] = @getId()
      else if edgeContext.status is EdgeAddingStatus.started
        console.log 'bbb ' + edgeContext.status
        edgeContext['to'] = @getId()

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

  Template.diagram.events({
    'click #add-node' : () ->
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

    'change #edge-mode' : (event) ->
      edgeContext['addingEdge'] = event.srcElement.checked
  })

if root.Meteor.isServer
  Meteor.startup ->
    console.log 'Server started!'
