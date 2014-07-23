class GraphNode
  constructor: (@title, @xpos, @ypos, @width, @height) ->
  centerX: -> @xpos + @width/2
  centerY: -> @ypos + @height/2
  @fromAttrs:(node) ->
    g = new GraphNode(node.title, node.xpos, node.ypos, node.width, node.height)
    g
  show: -> "title:#{@title} :#{@xpos} y:#{@ypos} width:#{@width} height:#{@height}"

class Edge
  constructor: (@from, @to) ->
  @startx: 0
  @starty: 0
  @endx: 0
  @endy: 0
  show: ->
    "from:#{@from}(#{@startx}, #{@starty}) to:#{@to}(#{@endx}, #{@endy})"

class Graph
  build: ->
    console.log 'Graph ready.'
  addNode: (title) ->
    graphNode = new GraphNode title, kineticContext.randomX(), kineticContext.randomY(), 0, 0
    console.log graphNode.show()
    if not GraphNodes.validate graphNode
      alert 'input invalid'
      return
    GraphNodes.insert graphNode, (error, id) ->
      if error
        console.log JSON.stringify error, null, 2
      else
        s = kineticFactory.createShape(graphNode, id)
        console.log "#{s.width()} #{s.height()}"
        GraphNodes.update {_id: id}, {$set: width: s.width(), height: s.height() }
        kineticContext.registerShape s
      id

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
        kineticContext.registerLine kineticFactory.createLine(edge, result)
      result

  addEdgeByIds: (fromId, toId) ->
    edge = new Edge(fromId, toId)
    from = GraphNodes.findOne _id: fromId
    to = GraphNodes.findOne _id: toId
    edge.startx = from.xpos + 43
    edge.starty = from.ypos + 15
    edge.endx = to.xpos + 36
    edge.endy = to.ypos + 15
    Edges.insert edge, (error, result) ->
      if error
        console.log JSON.stringify error, null, 2
      else
        console.log edge.show()
        kineticContext.registerLine kineticFactory.createLine edge, result

  moveNode: ->
    id = dragContext.nodeId
    x = dragContext.node.xpos
    y = dragContext.node.ypos
    GraphNodes.update {_id: id}, {$set: xpos: x, ypos: y}
    #console.log "#{dragContext.node.title} #{x} #{y}"

  moveEdges: ->
    x = dragContext.node.centerX()
    y = dragContext.node.centerY()
    _.each dragContext.froms, (from) ->
      Edges.update {_id: from._id}, {$set: startx: x, starty:y}
    _.each dragContext.tos, (to) ->
      Edges.update {_id: to._id}, {$set: endx: x, endy:y}

  getNode: (id) ->
    node = GraphNodes.findOne _id: id
    if node
      GraphNode.fromAttrs node

  findEdgesFrom: (nodeId) ->
    Edges.find({from: nodeId}).fetch()

  findEdgesTo: (nodeId) ->
    Edges.find({to: nodeId}).fetch()

@graph = new Graph
