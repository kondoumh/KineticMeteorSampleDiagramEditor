class KineticContext
  build: ->
    @stage = new Kinetic.Stage({
      container  : container
      width      : 800
      height     : 600
    })
    @layer = new Kinetic.Layer()
    .on 'mouseup tap', (event) ->
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
  dragEdges: ->
    l = @layer
    g = dragContext.node
    _.each dragContext.froms, (from) ->
      edgeId = from._id
      line = l.find("##{edgeId}")[0]
      if line
        points = line.attrs.points
        line.points [g.centerX(), g.centerY(), points[2], points[3]]
        l.draw()
    _.each dragContext.tos, (to) ->
      edgeId = to._id
      line = l.find("##{edgeId}")[0]
      if line
        points = line.attrs.points
        line.points [points[0], points[1], g.centerX(), g.centerY()]
        l.draw()

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
    graph.addEdge edgeContext

@kineticContext = new KineticContext
