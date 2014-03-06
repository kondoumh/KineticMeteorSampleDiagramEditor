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
  addNode: (title) ->
    graphNode = new GraphNode title, kContext.getRandomX(), kContext.getRandomY()
    console.log graphNode.show()
    if not GraphNodes.validate graphNode
      alert 'input invalid'
      return
    inserted = GraphNodes.insert graphNode, (error, result) ->
      if error
        console.log JSON.stringify error, null, 2
      else
        kContext.registerShape KineticFactory.createShape(graphNode, result)

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
      console.log "#{node.title} #{node.xpos}  #{node.ypos}"
    kContext.moveEdges(node)

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
    graph.addEdge(edgeContext)

###
###

class KineticContext
  build: ->
    @stage = new Kinetic.Stage({
      container  : container
      width      : 578
      height     : 200
    })
    @layer = new Kinetic.Layer()
    .on 'mouseup', (event) ->
      layerEdgeAction(event, @)
    @stage.add @layer
  getRandomX: ->
    parseInt Math.random()*(@stage.getWidth() - 100)
  getRandomY: ->
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
    found = Edges.find {from: node._id}
    if (found)
      edgeId = found.fetch()[0]._id
      line = @layer.find("##{edgeId}")[0]
      points = line.attrs.points
      line.points [node.xpos, node.ypos, points[2], points[3]]
      @layer.draw()

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
    .on 'dragmove', () ->
      console.log "#{@attrs.x}, #{@attrs.y}"
    .on 'dragend', () ->
      graph.moveNode(@getId(), @attrs.x, @attrs.y)
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
