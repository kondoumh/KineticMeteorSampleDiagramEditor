class GraphNode
  constructor: (@title, @xpos, @ypos) ->
  @width:0
  @height:0
  centerX: -> @xpos + @width/2
  centerY: -> @ypos + @height/2
  @fromAttrs:(node) ->
    g = new GraphNode(node.title, node.xpos, node.ypos)
    g.width = node.width
    g.height = node.height
    g
  show: -> "title:#{@title} x:#{@xpos} y:#{@ypos}"

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
  addNode: (title) ->
    graphNode = new GraphNode title, kContext.randomX(), kContext.randomY()
    console.log graphNode.show()
    if not GraphNodes.validate graphNode
      alert 'input invalid'
      return
    inserted = GraphNodes.insert graphNode, (error, id) ->
      if error
        console.log JSON.stringify error, null, 2
      else
        s = KineticFactory.createShape(graphNode, id)
        GraphNodes.update {_id: id}, {$set: width: s.width(), height: s.height() }
        kContext.registerShape s

  addEdge: (edgeContext) ->
    edge = new Edge(edgeContext.from, edgeContext.to)
    edge.startx = edgeContext.startx
    edge.starty = edgeContext.starty
    edge.endx = edgeContext.endx
    edge.endy = edgeContext.endy
    Edges.insert edge, (error, result) ->
      if error
        console.log JSON.stringify error, null, 2
      else
        console.log edge.show()
        kContext.registerLine KineticFactory.createLine(edge, result)

  moveNode: (id, x, y) ->
    GraphNodes.update {_id: id}, {$set: xpos: x, ypos: y}
    node = GraphNodes.findOne _id: id
    if node
      console.log "#{node.title} #{node.xpos} #{node.ypos}"
      kContext.moveEdges(node)

@graph = new Graph

###
EdgeActions
###

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

labelEdgeAction = (event, shape) ->
  if edgeContext.addingEdge
    if edgeContext.status is EdgeAddingStatus.nothing
      edgeContext['from'] = shape.getId()
      edgeContext['startx'] = shape.x() + shape.width()/2
      edgeContext['starty'] = shape.y() + shape.height()/2
    else if edgeContext.status is EdgeAddingStatus.started
      edgeContext['to'] = shape.getId()
      edgeContext['endx'] = shape.x() + shape.width()/2
      edgeContext['endy'] = shape.y() + shape.height()/2

layerEdgeAction = (event) ->
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
    graph.addEdge(edgeContext)

###
DragActions
###
@dragContext =
  nodeId:''
  node:null
  shape:null
  froms:[]
  tos:[]

dragStartAction = (event, shape) ->
  console.log 'drag began'
  dragContext.nodeId = shape.getId()
  node = GraphNodes.findOne _id: shape.getId()
  if node
    node.xpos = event.offsetX
    node.ypos = event.offsetY
    dragContext.node = node

dragMoveAction = (event, shape) ->
  console.log "#{shape.attrs.x}, #{shape.attrs.y}"
  dragContext.node.xpos = event.offsetX
  dragContext.node.ypos = event.offsetY
  kContext.moveEdges dragContext.node

dragEndAction = (shape) ->
  graph.moveNode dragContext.nodeId, shape.attrs.x, shape.attrs.y

class KineticContext
  build: ->
    @stage = new Kinetic.Stage({
      container  : container
      width      : 578
      height     : 200
    })
    @layer = new Kinetic.Layer()
    .on 'mouseup', (event) ->
      layerEdgeAction(event)
    @stage.add @layer
  randomX: ->
    parseInt Math.random()*(@stage.getWidth() - 100)
  randomY: ->
    parseInt Math.random()*(@stage.getHeight() - 50)
  registerShape: (label) ->
    @layer.add label
    applyTweenTo label.getTag()
    applyTweenTo label.getText()
    @layer.draw()
  registerLine: (line) ->
    @layer.add line
    line.moveToBottom()
    @layer.draw()
  applyTweenTo = (node) ->
    node.tween = new Kinetic.Tween({
      node: node
      scaleX: 1.2
      scaleY: 1.2
      easing: Kinetic.Easings.EaseInOut
      duration: 0.5
    })
  moveEdges: (node) ->
    froms = Edges.find({from: node._id}).fetch()
    tos = Edges.find({to: node._id}).fetch()
    l = @layer
    g = GraphNode.fromAttrs(node)
    _.each froms, (from) ->
      edgeId = from._id
      line = l.find("##{edgeId}")[0]
      if line
        points = line.attrs.points
        line.points [g.centerX(), g.centerY(), points[2], points[3]]
        l.draw()
    _.each tos, (to) ->
      edgeId = to._id
      line = l.find("##{edgeId}")[0]
      if line
        points = line.attrs.points
        line.points [points[0], points[1], g.centerX(), g.centerY()]
        l.draw()

@kContext = new KineticContext


class KineticFactory
  @createShape: (graphNode, id) ->
    new Kinetic.Label({
      x: graphNode.xpos
      y: graphNode.ypos
      width: 100
      height: 50
      draggable: true
      id: id
      name: graphNode.title
    })
    .on 'dragstart', () ->
      dragStartAction(event, @)
    .on 'dragmove', (event) ->
      dragMoveAction(event, @)
    .on 'dragend', () ->
      dragEndAction(@)
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
      fontSize: 14
      padding: 8
      fill: 'black'
    })

  @createLine: (edge, id) ->
    line = new Kinetic.Line({
      points: [edge.startx, edge.starty, edge.endx, edge.endy]
      stroke: 'black'
      strokeWidth: 4
      id: id
      name: 'test'
    })


root = global ? window

if root.Meteor.isClient

  Meteor.startup ->
    kContext.build()
    graph.addNode 'ふなっしー'
    graph.addNode 'ヒャハー'
    console.log 'client ready. ' + (->
      d = new Date
      "#{d.getHours()}:#{d.getMinutes()}:#{d.getSeconds()}")()

  Template.diagram.greeting = () ->
    'Welcome to dia-study.'

  Template.diagram.events({
    'click #add-node' : () ->
      graph.addNode $('#form-title').val()
      $('#form-title').val ''

    'change #edge-mode' : (event) ->
      edgeContext['addingEdge'] = event.srcElement.checked
  })

if root.Meteor.isServer
  Meteor.startup ->
    console.log 'Server started!'
