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
      console.log edgeContext.startx + ' ' + edgeContext.status
      console.log 'from ' + edgeContext.from
      return
    if edgeContext.status is EdgeAddingStatus.started
      edgeContext['status'] = EdgeAddingStatus.end
      console.log edgeContext.endx + ' ' + edgeContext.status
      console.log 'from ' + edgeContext.from + ' to ' + edgeContext.to
      edgeContext['status'] = EdgeAddingStatus.nothing
      console.log 'ready'
      if edgeContext.from is edgeContext.to
        return
      console.log 'go'
      line = new Kinetic.Line({
        points: [edgeContext.startx, edgeContext.starty, edgeContext.endx, edgeContext.endy]
        stroke: 'brack'
        strokeWidth: 4
      })
      context.layer.add line
      line.moveToBottom()
      context.layer.draw()

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
    if edgeContext.addingEdge
      @getTag().tween.play()
      @getText().tween.play()
  .on 'mouseout', () ->
    document.body.style.cursor = 'default'
    if edgeContext.addingEdge
      @getTag().tween.reverse()
      @getText().tween.reverse()
  .on 'mouseup', (event) ->
    console.log 'mouseup on label'
    if edgeContext.addingEdge
      if edgeContext.status is EdgeAddingStatus.nothing
        console.log 'aaa ' + edgeContext.status
        edgeContext['from'] = @getId()
        console.log event
        edgeContext['startx'] = event.layerX
        edgeContext['starty'] = event.layerY
      else if edgeContext.status is EdgeAddingStatus.started
        console.log 'bbb ' + edgeContext.status
        edgeContext['to'] = @getId()
        edgeContext['endx'] = event.layerX
        edgeContext['endy'] = event.layerY


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

createGraphNode = (name, context) ->
  graphNode =
    title: name
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


root = global ? window

if root.Meteor.isClient
  context = {}

  Meteor.startup ->
    buildContext context
    createGraphNode('ふなっしー', context);
    createGraphNode('ヒャハー', context);
    console.log 'client ready.'

  Template.diagram.greeting = () ->
    'Welcome to dia-study.'

  Template.diagram.events({
    'click #add-node' : () ->
      createGraphNode $('#form-title').val(), context
      $('#form-title').val ''

    'change #edge-mode' : (event) ->
      edgeContext['addingEdge'] = event.srcElement.checked
  })

if root.Meteor.isServer
  Meteor.startup ->
    console.log 'Server started!'
