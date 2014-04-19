@EdgeAddingStatus =
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

@dragContext =
  nodeId:''
  node: null
  shape: null
  froms: []
  tos: []
