class KineticFactory
  build: ->
    console.log 'factory ready'
  createShape: (graphNode, id) ->
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
      dragStartAction(@)
    .on 'dragmove', () ->
      dragMoveAction(@)
    .on 'dragend', () ->
      dragEndAction(@)
    .on 'mouseover touchstart', () ->
      document.body.style.cursor = 'pointer'
      if edgeContext.addingEdge
        @getTag().tween.play()
        @getText().tween.play()
    .on 'mouseout touchend', () ->
      document.body.style.cursor = 'default'
      if edgeContext.addingEdge
        @getTag().tween.reverse()
        @getText().tween.reverse()
    .on 'mouseup tap', (event) ->
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

  createLine: (edge, id) ->
    line = new Kinetic.Line({
      points: [edge.startx, edge.starty, edge.endx, edge.endy]
      stroke: 'black'
      strokeWidth: 4
      id: id
      name: 'test'
    })

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

dragStartAction = (shape) ->
  console.log 'drag began'
  dragContext.nodeId = shape.getId()
  node = graph.getNode shape.getId()
  if node
    node.xpos = shape.x()
    node.ypos = shape.y()
    dragContext.node = node
    dragContext.froms = graph.findEdgesFrom shape.getId()
    dragContext.tos = graph.findEdgesTo shape.getId()

dragMoveAction = (shape) ->
  console.log "#{shape.attrs.x}, #{shape.attrs.y}"
  dragContext.node.xpos = shape.x()
  dragContext.node.ypos = shape.y()
  kContext.dragEdges()

dragEndAction = (shape) ->
  dragContext.node.xpos = shape.x()
  dragContext.node.ypos = shape.y()
  graph.moveNode()
  kContext.dragEdges()
  graph.moveEdges()

@kineticFactory = new KineticFactory
