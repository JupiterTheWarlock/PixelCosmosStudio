extends HSlider

# A monotone rational mapping: endpoints stay valid, the authored default is 50%.
# Unlike two linear halves, the derivative is continuous at the default.
var low: float
var high: float
var center: float
var increment: float
var integer: bool

func setup(field: Array) -> void:
	low=float(field[3])
	high=float(field[4])
	center=float(field[2])
	increment=float(field[5])
	integer=field[2] is int
	min_value=0.0
	max_value=1.0
	step=0.0
	tick_count=3
	ticks_on_borders=true
	tooltip_text=tr("左端 %s · 中点（默认）%s · 右端 %s\n滑条非等距，数值框显示实际值；双击滑条回到默认。")%[str(low),str(center),str(high)]
	set_value_no_signal(.5)
	custom_minimum_size.y=18

func to_actual(position: float) -> float:
	var t: float=clampf(position,0,1)
	if t<=0: return low
	if t>=1: return high
	if absf(t-.5)<.000001: return center
	if center<=low or center>=high: return low+(high-low)*t
	var k: float=(center-low)/(high-center)
	var actual: float=low+(high-low)*k*t/(1.0+(k-1.0)*t)
	# Snap around the intended default, so dragging does not silently alter it.
	actual=center+round((actual-center)/increment)*increment
	return clampf(round(actual) if integer else actual,low,high)

func to_position(actual: float) -> float:
	var u: float=clampf((actual-low)/(high-low),0,1)
	if center<=low or center>=high: return u
	var k: float=(center-low)/(high-center)
	return u/(k+(1.0-k)*u)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.double_click:
		value=to_position(center)
		accept_event()
