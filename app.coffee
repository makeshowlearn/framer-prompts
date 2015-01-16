# References
# https://snipt.net/vmedium/material-design-easing-curves-for-framer-495cf12b/
# https://layervault.com/tack-mobile/artboards-framer/nav--sketch/revisions/1
window.myLayers = Framer.Importer.load("imported/prompts")

# store original frames https://medium.com/framer-js/ca55fc7cfc61
for key, value of myLayers
  myLayers[key].originalFrame = myLayers[key].frame
  myLayers[key].originalFrame.screenFrame = myLayers[key].screenFrame

#myLayers.statusbar.x = 0

# animation timing for moving on screen
Animation = {}
Animation.onScreen =
  curve: "bezier-curve", curveOptions: [0.4, 0, 0.2, 1], time: 0.7

# Add to main stage and animate on screen
Layer::enterRight = ->
  addToStage @
  @x = 375
  @animate
    properties:
      x: 0
    curveOptions: [0.4, 0, 0.2, 1]
    curve: "bezier-curve"
    time: 0.7

# Animate off screen then remove from main stage
Layer::exitLeft = ->
  exitAnimation = @animate
    properties:
      x: -@width
    curveOptions: [0.4, 0, 0.2, 1]
    curve: "bezier-curve"
    time: 0.7
  exitAnimation.on Events.AnimationEnd, ->
    removeFromStage @
  return exitAnimation

# Create stage layer
stage = new Layer
  width: 375
  height: 667
#  backgroundColor: "#ECEFF1"
#  backgroundColor: "red"
  backgroundColor: "#82BEF9"
  clip: true

Layer::pullIntoLimbo = ->
  @superLayer = stage
  @x = @originalFrame.screenFrame.x
  @y = @originalFrame.screenFrame.y

# Pull statusbar off artboard so it's always on top
#stage.center()
#stage.pixelAlign()

addToStage = (layer) ->
  layer.superLayer = stage
  layer.x = layer.originalFrame.x
  layer.visible = true

removeFromStage = (layer) ->
  layer.superLayer = null
  layer.visible = false

addToStage myLayers.section0


Animation.stiffSpring =
  curve: "spring-rk4"
  curveOptions:
    tension: 100
    friction: 20
    velocity: 10

# animation for states
myLayers.keyboard.states.animationOptions = curve: "bezier-curve", curveOptions: [0.4, 0, 0.2, 1], time: 0.75
myLayers.prompt.states.animationOptions = curve: "bezier-curve", curveOptions: [0.4, 0, 0.2, 1], time: 0.75


# set up arrays of similar elements
sections = _.filter myLayers, (layer) -> ~layer.name.indexOf "section"
typeareas = _.filter myLayers, (layer) -> ~layer.name.indexOf "typearea"
prompts = _.filter myLayers, (layer) -> ~layer.name.indexOf "prompt"

prompts.forEach (element, index) ->
  element.states.animationOptions = curve: "bezier-curve", curveOptions: [0.4, 0, 0.2, 1], time: 0.75

typeareas.forEach (element, index) ->
  content = localStorage.getItem 'prompt' + index

  if (content == null || content == undefined) # null/undefined check
    element.html = '<div class="content" id="content' + index + '" contenteditable="true"></div>'
  else
    element.html = content
  element.ignoreEvents = false

# Keyboard setup
myLayers.keyboard.states.add
  active:
    y: myLayers.keyboard.originalFrame.y
  inactive:
    y: 667

myLayers.keyboard.states.switchInstant "inactive"
if Utils.isMobile() == false
#  alert "test"
  myLayers.keyboard.states.switch "active"
  myLayers.keyboard.bringToFront()
  myLayers.keyboard.pullIntoLimbo()

# Prompt setup
myLayers.prompt.states.add
  active:
    y: myLayers.prompt.originalFrame.y
  inactive:
    y: -100

myLayers.prompt.states.switchInstant "inactive"
myLayers.prompt.states.switch "active"
prompts.forEach (element, index) ->
  element.name = "prompt" + index

#  element.borderRadius = 10

# Set states up on small boxes
sections.forEach (element, index) ->
  element.backgroundColor = "#fff"
  element.borderRadius = 10
  element.states.add
    default:
      scale: 1
      y: 0
      shadowY: 0
      shadowBlur: 0
    back:
      scale: 0.9
      y: 20
      shadowY: 2
      shadowBlur: 10
#  element.states.animationOptions = curve: "bezier-curve", curveOptions: [0.4, 0, 0.2, 1], time: 0.25
  element.states.animationOptions = Animation.stiffSpring


  element.shadowColor = "rgba(0, 0, 0, 0.3)"

myLayers.keyboard.on Events.Click, ->
#  sections.forEach (element, index) ->
#    element.states.switch "back"
  animationNext = goNext()
  animationNext.on Events.AnimationEnd, ->
    sections.forEach (element, index) ->
      element.states.switch "default"

    typeareas.forEach (element, index) ->
      localStorage.setItem 'prompt' + index, element.html

    currentPos = slider.states.current.slice(-1)
    document.getElementById("content" + currentPos).focus()

    ### SET FOCUS FUNCTION, DO THIS WHEN IT GETS BIG ###

  # set focus
#  currentPos = slider.states.current.slice(-1)
#  document.getElementById("content" + currentPos).focus()


#  animPushback = myLayers.section0.states.switch "back"
#
#  animPushback.on Events.AnimationEnd, ->
#    animSlideleft = myLayers.section0.exitLeft()
#    myLayers.section1.states.switchInstant "back"
#    myLayers.section1.enterRight()
#    myLayers.keyboard.bringToFront()
#
#    animSlideleft.on Events.AnimationEnd, ->
#      myLayers.section1.states.switch "default"

slider = new Layer
  superLayer: stage
  width: sections.length * 375
  height: 667
  backgroundColor: "none"

sections.forEach (element, index) ->
  element.visible = true
  element.superLayer = slider
  element.x = index * 375

myLayers.keyboard.bringToFront()



# Tapping the prompt should bring us to the view where we can go from prompt to prompt.
# Look at the flick scrolling here:
# http://framerjs.com/examples/preview/#draggable-range.framer#code
prompts.forEach (element, index) ->
  element.on Events.Click, ->
    console.log @superLayer.states.current
    if @superLayer.states.current is "default"
      sections.forEach (element, index) =>
        if _.contains(element.subLayers, @) == false
          element.states.switchInstant "back"
        else
          element.states.switch "back"

      slider.draggable.enabled = true
      disableEditable()
    else
      sections.forEach (element, index) =>
        if _.contains(element.subLayers, @) == false
          element.states.switchInstant "default"
        else
          element.states.switch "default"

      slider.draggable.enabled = false
      enableEditable()

      currentPos = slider.states.current.slice(-1)
      document.getElementById("content" + currentPos).focus()

    updateWordCount()
#    slider.draggable.enabled = true

# disable contenteditable
disableEditable = ->
  for element, index in document.getElementsByClassName('content')
    element.contentEditable = false

enableEditable = ->
  for element, index in document.getElementsByClassName('content')
    element.contentEditable = true

# Adapting from hierarchical timing
startX = 0
changeX = 0
threshold = 120

slider.draggable.speedY = 0
slider.on Events.DragStart, (event) ->
  startX = event.pageX

slider.on Events.DragMove, (event) ->
  changeX = event.pageX - startX
  currentPos = slider.states.current.slice(-1)

  # If we reach the threshold, trigger move
  if changeX < -threshold
    goNext()
  else if changeX > threshold
    goPrev()

slider.on Events.DragEnd, (event) ->
  if changeX > -threshold
    if changeX < threshold
      snapBack()

wordcount = new Layer
  width: 375
  height: 100
  y: 20
  backgroundColor: 'none'
  superLayer: stage

wordcount.html = '<p class="wordcount">Today\'s word count: 730</p>'
wordcount.sendToBack()


#  @draggable.enabled = true
#
#slider.on Events.StateWillSwitch, ->
#  @draggable.enabled = false

slider.states.animationOptions =
#  curve: "bezier-curve", curveOptions: [0.4, 0, 0.2, 1], time: 0.4
#  curve: "bezier-curve", curveOptions: [0.4, 0, 0.2, 1], time: 0.4
#  curve: "bezier-curve", curveOptions: [0.4, 0, 0.2, 1], time: 0.4
  curve: "spring(200,20,10)"
#  Animation.stiffSpring

snapBack = ->
  currentPos = slider.states.current.slice(-1)
  slider.states.switch "pos" + currentPos

goNext = (direction) ->
  currentPos = slider.states.current.slice(-1)
#  console.log currentPos
  if currentPos > sections.length - 2
    nextPos = 0
    # slow animation down
    slider.states.animationOptions =
      curve: "spring(75,20,1)"
  else
    nextPos = parseInt(currentPos) + 1

  slider.states.switch "pos" + nextPos
  slider.states.animationOptions =
    curve: "spring(200,20,10)"

updateWordCount = ->
  typetotal = 0
  words = 0
  regex = /\s+/gi
  typeareas.forEach (element, index) ->
    value = element.html
    words = value.trim().replace(regex, ' ').split(' ').length - 3
#    console.log words
    typetotal += words
    # save to local storage
    localStorage.setItem 'prompt' + index, element.html

  wordcount.html = '<p class="wordcount">Today\'s word count: ' + typetotal + '</p>'


# We want to debounce otherwise we'll trigger a bunch
# of movements while dragging
goNext = _.debounce goNext, 100, true

goPrev = ->
  currentPos = slider.states.current.slice(-1)
#  console.log currentPos
  prevPos = parseInt(currentPos) - 1

  # Cancel move if we're on first slide
  if currentPos == "0"
    slider.states.switch "pos0"
    return

  slider.states.switch "pos" + prevPos
#  closeBoxes myLayers["boxes" + currentPos]

#  Utils.delay 0.3, ->
#    openBoxes myLayers["boxes" + prevPos]

goPrev = _.debounce goPrev, 100, true

# Set snap positions for big boxes
slider.states.add
  pos0:
    x: 0
  pos1:
    x: -375
  pos2:
    x: -750
  pos3:
    x: -1125
  pos4:
    x: -375 * 4

startingPos = _.random(0, 4)
slider.states.switchInstant "pos" + startingPos
slider.draggable.enabled = false

#updateWordCount()


#document.addEventListener 'keydown', (event, layer) ->
#  keyCode = event.which
#  switch key
#      when 13
#        animationNext = goNext()
#        animationNext.on Events.AnimationEnd, ->
#          sections.forEach (element, index) ->
#            element.states.switch "default"
#
#          typeareas.forEach (element, index) ->
#            localStorage.setItem 'prompt' + index, element.html
#
#          currentPos = slider.states.current.slice(-1)
#          document.getElementById("content" + currentPos).focus()




#$(document).bind('keyup keydown', function(e) {
#shifted = e.shiftKey;
#return cntrled = e.metaKey || e.ctrlKey;
#});

