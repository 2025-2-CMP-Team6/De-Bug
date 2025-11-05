# actors/enemies/bullet.gd
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 400.0

func _physics_process(delta: float):
    global_position += direction * speed * delta


# 'Bullet (Area2D)'가 'Player (CharacterBody2D)'와 부딪혔을 때 호출됨
func _on_body_entered(body):
    # 1. 부딪힌 body(Player)가 'lose_life' 함수를 가졌는지 확인
    if body.has_method("lose_life"):
        # 2. 가졌다면, 플레이어의 'lose_life' 함수 호출
        body.lose_life()
        
        # 3. ★★★ 수정된 부분 ★★★
        # '플레이어'와 부딪혔을 때만 총알 삭제
        queue_free()
    
    # (부딪힌 게 Enemy 자신이나 다른 총알이라면 '무시'하고 통과)


# 'VisibleOnScreenNotifier2D'가 화면 밖으로 나갔을 때 호출됨
func _on_screen_exited():
    queue_free()