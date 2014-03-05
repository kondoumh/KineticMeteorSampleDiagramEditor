class GraphNode
  constructor: (@title, @xpos, @ypos) ->
  show: ->
    "title:#{@title} x:#{@xpos} y:#{@ypos}"

@GraphNodes = new Meteor.Collection 'GraphNodes'

@GraphNodes.validate = (graphNode) ->
  if graphNode.title then true else false

class Edge
  constructor: (@from, @to) ->
  @startx: 0
  @starty: 0
  @endx: 0
  @endy: 0
  show: ->
    "from:#{@from}(#{@startx}, #{@starty}) to:#{@to}(#{@endx}, #{@endy})"

@Edges = new Meteor.Collection 'Edges'


class Graph
  addNode: (graphNode) ->
    console.log graphNode.show()
  addEdge: (edge) ->
    console.log edge.show()

@graph = new Graph

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


###
EdgeActions
###
labelEdgeAction = (event, node) ->
  if edgeContext.addingEdge
    if edgeContext.status is EdgeAddingStatus.nothing
      edgeContext['from'] = node.getId()
      edgeContext['startx'] = event.layerX
      edgeContext['starty'] = event.layerY
    else if edgeContext.status is EdgeAddingStatus.started
      edgeContext['to'] = node.getId()
      edgeContext['endx'] = event.layerX
      edgeContext['endy'] = event.layerY

layerEdgeAction = (event, layer) ->
  if not edgeContext.addingEdge
    return
  if edgeContext.status is EdgeAddingStatus.nothing
    edgeContext['status'] = EdgeAddingStatus.started
    return
  if edgeContext.status is EdgeAddingStatus.started
    edgeContext['status'] = EdgeAddingStatus.end
    edgeContext['status'] = EdgeAddingStatus.nothing
    if edgeContext.from is edgeContext.to
      return
    edge = new Edge(edgeContext.from, edgeContext.to)
    edge.startx = edgeContext.startx
    edge.starty = edgeContext.starty
    edge.endx = edgeContext.endx
    edge.endy = edgeContext.endy
    graph.addEdge edge
    Edges.insert edge, (error, result) ->
      if error
        console.log JSON.stringify error, null, 2
      else
        line = new Kinetic.Line({
          points: [edge.startx, edge.starty, edge.endx, edge.endy]
          stroke: 'brack'
          strokeWidth: 4
        })
        layer.add line
        line.moveToBottom()
        layer.draw()
###
###

buildKineticContext = (context) ->
  context.stage = new Kinetic.Stage({
    container  : container
    width      : 578
    height     : 200
  })
  context.layer = new Kinetic.Layer()
  .on 'mouseup', (event) ->
    layerEdgeAction(event, @)

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

addTweenEffect = (node) ->
  node.tween = new Kinetic.Tween({
    node: node
    scaleX: 1.2
    scaleY: 1.2
    easing: Kinetic.Easings.EaseInOut
    duration: 0.5
  })

createShape = (graphNode, id) ->
  new Kinetic.Label({
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
    labelEdgeAction(event, @)
  .add new Kinetic.Tag({
    fill: ((length) ->
      if length % 5 is 0
        'green'
      else if length % 3 is 0
        'red'
      else if length % 2 is 0
        'pink'
      else
        'yellow'
      )(graphNode.title.length)
    stroke: 'black'
    strokeWidth: 4
  })
  .add new Kinetic.Text({
    text: graphNode.title
    fontSize: 18
    padding: 10
    fill: 'black'
  })

createGraphNode = (title) ->
  graphNode = new GraphNode title, context.getRandomX(), context.getRandomY()
  graph.addNode graphNode

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
    buildKineticContext context
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
