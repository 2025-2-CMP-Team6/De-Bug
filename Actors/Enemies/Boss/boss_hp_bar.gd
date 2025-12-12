# boss_hp_bar.gd
extends CanvasLayer

@onready var health_bar = $Control/VBoxContainer/ProgressBar
@onready var label = $Control/VBoxContainer/Label
@onready var disappear_timer = $DisappearTimer

# 처음 셋팅
func initialize(enemy_name: String, max_hp: float, current_hp: float):
	if label:
		label.text = enemy_name
	
	health_bar.max_value = max_hp
	health_bar.value = current_hp
	visible = false

# 피격 시 업데이트
func update_health(current_hp: float):
	visible = true
	# 부드러운 감소 효과 (선택 사항)
	var tween = create_tween()
	tween.tween_property(health_bar, "value", current_hp, 0.2)
	# health_bar.value = current_hp # 트윈 안 쓸거면 그냥 이렇게
	disappear_timer.start()
	
func _on_disappear_timer_timeout() -> void:
		visible = false

# 보스 사망 시 UI 삭제
func on_boss_died():
	queue_free()
