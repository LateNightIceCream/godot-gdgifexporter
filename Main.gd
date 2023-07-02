extends Control

const GIFExporter := preload("res://gdgifexporter/exporter.gd")
const MedianCutQuantization := preload("res://gdgifexporter/quantization/median_cut.gd")
const UniformQuantization := preload("res://gdgifexporter/quantization/uniform.gd")

var img1: Image
var img2: Image
var img3: Image
var img4: Image

var export_thread := Thread.new()
var timer := 0.0
var should_count := false
var count_mutex := Mutex.new()

var imgs := []


func _ready():
	img1 = Image.new()
	img2 = Image.new()
	img3 = Image.new()
	img4 = Image.new()
	img1.load("res://imgs/colors2.png")
	img1.convert(Image.FORMAT_RGBA8)
	img2.load("res://imgs/colors.png")
	img2.convert(Image.FORMAT_RGBA8)
	img3.load("res://imgs/one_color.png")
	img3.convert(Image.FORMAT_RGBA8)
	img4.load("res://imgs/half_transparent.png")
	img4.convert(Image.FORMAT_RGBA8)
	var img_texture := ImageTexture.create_from_image(img1)
	$CenterContainer/VBoxContainer/TextureRect.texture = img_texture


func _process(delta):
	count_mutex.lock()
	if should_count:
		timer += delta
	count_mutex.unlock()


func _exit_tree():
	export_thread.wait_to_finish()


func export_thread_method(_args: Dictionary):
	count_mutex.lock()
	should_count = true
	count_mutex.unlock()
	var exporter := GIFExporter.new(img1.get_width(), img1.get_height())
	exporter.add_frame(img1, 1, MedianCutQuantization)
	exporter.add_frame(img2, 1, MedianCutQuantization)
	exporter.add_frame(img3, 1, MedianCutQuantization)
	exporter.add_frame(img4, 1, MedianCutQuantization)

	print("DONE")
	count_mutex.lock()
	should_count = false
	print("Time took: " + str(timer))
	timer = 0
	count_mutex.unlock()

	var file := FileAccess.open("user://result.gif", FileAccess.WRITE)
	file.store_buffer(exporter.export_file_data())
	file.close()


func _on_Button_pressed():
	if not should_count:
		if export_thread.is_started():
			export_thread.wait_to_finish()
		export_thread = Thread.new()
		export_thread.start(Callable(self, "export_thread_method").bind({}))
