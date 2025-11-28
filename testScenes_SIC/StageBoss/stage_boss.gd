# stage_boss.gd
extends Node2D


func _on_boss_pattern_started(pattern_name):
    if pattern_name == "pattern1":
        # 맵 패턴 1 실행
        print("Executing map pattern 1")
    elif pattern_name == "pattern2":
        # 맵 패턴 2 실행
        print("Executing map pattern 2")
    elif pattern_name == "pattern3":
        # 맵 패턴 3 실행
        print("Executing map pattern 3")