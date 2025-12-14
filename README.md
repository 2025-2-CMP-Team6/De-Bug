# 🎮 De-Bug

**A 2D Action Platformer Game**

*2025-2 Creative Media Programming - Team 6 Final Godot Project*

[![GitHub](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/2025-2-CMP-Team6/De-Bug)

---

## 📑 Table of Contents

- [Game Overview](#-game-overview)
- [Project Architecture](#-project-architecture)
- [Stage Flow & Features](#-stage-flow--features)
- [Directory Structure](#-directory-structure)
- [Core Systems](#-core-systems)
- [Scripts Documentation](#-scripts-documentation)
- [User Manual](#-user-manual)
- [Borrowed Contents](#-borrowed-contents)
- [AI Tools Declaration](#-ai-tools-declaration)
- [Technical Specifications](#-technical-specifications)

---

## 🎯 Game Overview

**De-Bug** is a 2D action platformer game where players progress through stages by collecting various "Skill Fragments." The core mechanics revolve around:

| Feature | Description |
|---------|-------------|
| ⚔️ **Skill Collection** | Gather skill fragments from cleared stages to expand your arsenal |
| ⬆️ **Skill Enhancement** | Upgrade skills using collected fragments with probability-based success |
| 🔮 **Skill Synthesis** | Combine fragments to create new, random skills |
| 🎰 **Strategic Slot Management** | Manage a limited 3-skill slot system to adapt to different combat situations |

### Game Structure (Chapter 1)

| Stage | Name | Description |
|-------|------|-------------|
| 1 | **Pixel City** | Tutorial Stage - Learn basic controls and mechanics |
| 2 | **Data Jungle** | Forest-themed environment with new enemy types |
| 3 | **Forgotten Memory Cemetery** | Graveyard setting with traps and aerial enemies |
| 4 | **Citadel of the Core** | Final approach with spike traps and flying enemies |
| 👾 | **Corrupt Core** | Boss Stage - Final boss encounter with multiple attack patterns |

---

## 🏗️ Project Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           AUTOLOAD (Singletons)                             │
├──────────────────┬──────────────────┬──────────────────┬────────────────────┤
│   GameManager    │ InventoryManager │   EffectManager  │   SceneTransition  │
│  (State Machine) │  (Skills/Items)  │    (VFX/SFX)     │   (Fade Effects)   │
└────────┬─────────┴────────┬─────────┴────────┬─────────┴────────────────────┘
		 │                  │                  │
		 ▼                  ▼                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                     WORLD (Stage 1 ~ 4 / Boss Stage)                        │
│              - Stage management, Portal system, Enemy tracking              │
└─────────────────────────────────────────────────────────────────────────────┘
		 │
		 ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                                  ACTORS                                     │
├────────────────────────────────────┬────────────────────────────────────────┤
│              PLAYER                │                ENEMIES                 │
│  - Movement & Input                │  - BaseEnemy (Abstract)                │
│  - Skill Casting                   │  - Common Enemies (Virus types)        │
│  - Health & Stamina                │  - Middle Bosses                       │
│  - Equipment Slots                 │  - Final Boss (Corrupt Core)           │
└────────────────────────────────────┴────────────────────────────────────────┘
		 │
		 ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              SKILL SYSTEM                                   │
├───────────────────────┬───────────────────────┬─────────────────────────────┤
│       BaseSkill       │     SkillInstance     │      Individual Skills      │
│       (Abstract)      │     (Data Class)      │  (FireBall, Heal, Slash...) │
└───────────────────────┴───────────────────────┴─────────────────────────────┘
		 │
		 ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                               UI SYSTEM                                     │
├───────────────────────┬───────────────────────┬─────────────────────────────┤
│        SkillUI        │      SkillGetUI       │       HUD Components        │
│    (Equip/Upgrade)    │    (Reward Screen)    │  (Health, Stamina, Skills)  │
└───────────────────────┴───────────────────────┴─────────────────────────────┘
```

### Design Patterns Used

- **Singleton Pattern**: Autoload managers (GameManager, InventoryManager, EffectManager)
- **State Machine**: Player and enemy state management
- **Observer Pattern**: Signal-based event system for enemy deaths, skill events
- **Component Pattern**: Modular skill system with BaseSkill inheritance

---

## 🗺️ Stage Flow & Features

### Stage Progression Flow

```
┌──────────┐    ┌───────────┐    ┌──────────┐    ┌──────────┐    ┌──────────────┐
│ Stage 1  │ ─→ │ Stage 2   │ ─→ │ Stage 3  │ ─→ │ Stage 4  │ ─→ │  Boss Stage  │
│Pixel City│    │Data Jungle│    │ Cemetery │    │ Citadel  │    │ Corrupt Core │
└──────────┘    └───────────┘    └──────────┘    └──────────┘    └──────────────┘
```

### Stage Details

#### Stage 1: Pixel City (Tutorial)

**Script:** `Stage1.gd` extends World

| Feature | Description |
|---------|-------------|
| 📚 Tutorial System | DashTutorial, SkillTutorial, MiddleBossTutorial triggers with dialogue |
| 👾 Enemies | Virus (basic), TutorialBoss (mini-boss) |
| 🎬 Camera Effects | Intro zoom effect, portal zoom cutscene |
| 💾 Checkpoint System | Respawn at last defeated enemy position |
| 🌧️ Visual Effects | Rain shader, parallax city background |
| 🔓 Unlock Features | Skill window unlocked after TutorialBoss defeat |

**Transitions to:** Stage 2 (Data Jungle) via portal

---

#### Stage 2: Data Jungle

**Script:** `Stage2.gd` extends World

| Feature | Description |
|---------|-------------|
| 👾 Enemies | Virus, RangeVirus (ranged attacks), JungleBoss |
| 🌿 Environment | 6-layer parallax jungle background |
| ⚠️ Hazards | Fall prevention zones, monster movement limits |
| 🎵 Audio | Jungle-themed BGM |

**Transitions to:** Stage 3 (Forgotten Memory Cemetery) via portal

---

#### Stage 3: Forgotten Memory Cemetery

**Script:** `Stage3.gd` extends World

| Feature | Description |
|---------|-------------|
| 👾 Enemies | FlyEnemy (aerial), HoverEnemy (stationary), FlyBoss (mid-boss) |
| 💀 Traps | BoobyTrap.gd - environmental hazards |
| 🌙 Environment | Mountains, graveyard decorations, dark atmosphere |
| 🎵 Audio | Scary cinematic background music |

**Transitions to:** Stage 4 (Citadel of the Core) via portal

---

#### Stage 4: Citadel of the Core

**Script:** `Stage4.gd` extends World

| Feature | Description |
|---------|-------------|
| 👾 Enemies | FlyEnemy, HoverEnemy (increased difficulty) |
| ⚡ Traps | 16-bit spike traps, environmental hazards |
| 🏰 Environment | Gothic columns, castle-themed tileset |
| 🎵 Audio | Church organ music for ominous atmosphere |

**Transitions to:** Boss Stage (Corrupt Core) via portal

---

#### Boss Stage: Corrupt Core

**Script:** `stage_boss.gd` extends World

| Component | File | Description |
|-----------|------|-------------|
| 👹 **Boss Entity** | `BossVirus.tscn` | Main boss character (HP: 300, Effect Size: 5x) |
| 🔥 **Fire Pattern** | `BossFire.tscn` | Fire-based projectile attacks |
| ⚡ **Laser Pattern** | `BossLaser.tscn` | Two edge-mounted lasers for sweeping attacks |
| ☄️ **Meteor Pattern** | `BossMeteor.tscn` | Falling meteor hazards with area damage |
| 🛡️ **Player Buff** | - | Max lives increased to 15 for boss fight |
| 🎵 **Audio** | - | Intense boss fight BGM |

> **Architecture Note:** The boss stage uses a unique architecture where attack patterns are instantiated as separate scene components (`map_lasers`) managed by the stage script rather than the boss AI. This allows for complex choreographed attack sequences and independent pattern timing via `StageTimer`.

---

### Common Stage Features

| Feature | Description | Implementation |
|---------|-------------|----------------|
| Portal System | Stage transition after defeating all enemies | `portal_enabled` flag + `SceneTransition.fade_to_scene()` |
| Enemy Tracking | Monitors remaining enemies, activates portal when cleared | `enemy_died` signal connection in World.gd |
| Reward System | Skill selection after stage clear | `SkillGetUI.open_reward_screen()` |
| Fall Prevention | Respawn player if falling off map | `FallPrevention` Area2D nodes |
| Camera Limits | Restrict camera to stage boundaries | `CameraMapLimit` sprite group |

---

## 📁 Directory Structure

```
De-Bug/
├── Actors/                          # All game characters
│   ├── Enemies/                     # Enemy implementations
│   │   ├── BaseEnemy.gd            # Abstract base class for all enemies
│   │   ├── RangedEnemy.gd          # Ranged attack enemy base
│   │   ├── Comon/virus/            # Common enemy types
│   │   │   ├── virus.gd/tscn       # Basic ground virus enemy
│   │   │   ├── fly_enemy.gd/tscn   # Flying virus enemy
│   │   │   ├── hover_enemy.gd/tscn # Hovering enemy
│   │   │   └── range_virus.gd/tscn # Ranged attack virus
│   │   ├── MiddleBoss/             # Mid-stage boss enemies
│   │   │   ├── TutorialBoss/       # Stage 1 mini-boss
│   │   │   └── JungleBoss/         # Stage 2 mini-boss
│   │   └── Boss/                   # Final boss (Corrupt Core)
│   │       ├── BossVirus.tscn      # Main boss entity
│   │       ├── BossFire.tscn       # Fire attack pattern
│   │       ├── BossLaser.tscn      # Laser attack pattern
│   │       ├── BossMeteor.tscn     # Meteor attack pattern
│   │       └── boss_hp_bar.gd      # Boss HP UI
│   └── Player/                     # Player character
│       ├── player.gd               # Main player controller
│       └── player.tscn             # Player scene
│
├── SkillDatas/                     # Skill system
│   ├── BaseSkill.gd                # Abstract base class for skills
│   ├── Skill_BlinkSlash/           # Teleport slash skill
│   ├── Skill_FireBall/             # Fireball projectile
│   ├── Skill_IceBall/              # Ice projectile
│   ├── Skill_Heal/                 # Basic heal
│   ├── Skill_GreatHeal/            # Enhanced heal
│   ├── Skill_Slash/                # Melee slash
│   ├── Skill_ThunderSlash/         # Thunder-enhanced slash
│   ├── Skill_MultiShot/            # Multiple projectiles
│   ├── Skill_PiercingShot/         # Piercing projectile
│   └── Skill_Parry/                # Defensive parry
│
├── UI/                             # User interface
│   ├── SkillUI.gd/tscn             # Main skill management UI
│   ├── SkillGetUI.gd/tscn          # Reward/skill selection UI
│   ├── SkillCard.gd                # Individual skill card display
│   ├── SkillHudIcon.gd/tscn        # HUD skill icon
│   ├── EquipSlot.gd                # Equipment slot handler
│   └── InventoryDropArea.gd        # Drag-drop inventory area
│
├── testScenes_SIC/                 # Stage implementations
│   ├── Stage1/Stage1.gd            # Tutorial stage (Pixel City)
│   ├── Stage2/Stage2.gd            # Data Jungle
│   ├── Stage3/Stage3.gd            # Forgotten Memory Cemetery
│   ├── Stage4/Stage4.gd            # Citadel of the Core
│   ├── StageBoss/stage_boss.gd     # Boss stage (Corrupt Core)
│   └── dialogue/                   # Dialogue files
│
├── world/                          # World and stage management
│   ├── world.gd/tscn               # Base world class
│   ├── StartScreen/                # Title screen
│   └── Option/                     # Options menu
│
├── effects/                        # Visual effects
├── autoload/                       # Autoload scripts
├── addons/                         # Third-party plugins
├── graphics/                       # Visual assets
├── Sounds/                         # Audio assets
├── Block/                          # Environment blocks
│
├── GameManager.gd                  # Global game state manager
├── InventoryManager.gd             # Skill inventory system
├── EffectManager.gd                # Visual/audio effects manager
├── SkillInstance.gd                # Skill data resource class
├── SkillUpgradeData.gd             # Skill upgrade configuration
└── project.godot                   # Godot project configuration
```

---

## ⚙️ Core Systems

### 1. GameManager (Autoload)

**File:** `GameManager.gd`

Manages the global game state using a state machine pattern.

| State | Description |
|-------|-------------|
| `IDLE` | Player is stationary |
| `MOVE` | Player is moving |
| `DASH` | Player is dashing (invincible) |
| `SKILL_CASTING` | Player is using a skill |

---

### 2. InventoryManager (Autoload)

**File:** `InventoryManager.gd`

Handles all skill-related data management.

**Key Methods:**
- `add_skill_to_inventory()` - Add skill to player inventory
- `remove_skill_from_inventory()` - Remove skill from inventory
- `attempt_upgrade()` - Try to upgrade a skill with another
- `get_random_skill_path()` - Get random skill for rewards

---

### 3. EffectManager (Autoload)

**File:** `EffectManager.gd`

Centralizes all visual and audio effects.

| Effect | Description |
|--------|-------------|
| Screen Shake | Camera shake effects for impact feedback |
| Screen Flash | Single and multi-flash effects |
| Hit Particles | Particle effects on damage |
| Shader Effects | Hit flash using shaders |

---

### 4. SceneTransition (Autoload)

**File:** `autoload/SceneTransition.gd`

Handles smooth scene transitions with fade effects.

---

## 📜 Scripts Documentation

### Player System - player.gd

Main player controller handling movement, skills, and combat.

**Key Properties:**
```gdscript
@export var max_speed: float = 400.0
@export var jump_velocity: float = -600.0
@export var max_jumps: int = 2
@export var dash_speed: float = 1200.0
@export var max_lives: int = 3
@export var max_stamina: float = 100.0
```

---

### Enemy System - BaseEnemy.gd

Abstract base class for all enemies providing:
- Health management
- Damage handling with i-frames
- Death signal emission
- Boss HP bar support
- Hit flash shader integration

---

### Final Boss - Corrupt Core

**Location:** `testScenes_SIC/StageBoss/`

The final boss is implemented as a composite system with separate attack pattern components:

| Component | File | Description |
|-----------|------|-------------|
| **Boss Entity** | `BossVirus.tscn` | Main boss character (HP: 300, Effect Size: 5x) |
| **Fire Pattern** | `BossFire.tscn` | Fire-based projectile attacks |
| **Laser Pattern** | `BossLaser.tscn` | Two edge-mounted lasers for sweeping attacks |
| **Meteor Pattern** | `BossMeteor.tscn` | Falling meteor hazards with area damage |
| **Stage Controller** | `stage_boss.gd` | Coordinates patterns via StageTimer |

> **Architecture Note:** The boss stage uses a unique architecture where attack patterns are instantiated as separate scene components (`map_lasers`) managed by the stage script rather than the boss AI. This allows for complex choreographed attack sequences and independent pattern timing.

---

### Skill System - BaseSkill.gd

Abstract base for all skills with:
- Skill properties (name, description, icon)
- Cooldown management
- Stamina cost
- Sound effect support
- Level-based upgrade system

---

## 📖 User Manual

### Controls

| Action | Key(s) |
|--------|--------|
| Move Left | `A` or `←` |
| Move Right | `D` or `→` |
| Jump | `W` or `↑` |
| Double Jump | Press jump again while airborne |
| Dash | `Shift` |
| Skill Slot 1 | `LMB` or `Z` |
| Skill Slot 2 | `Q` or `X` |
| Skill Slot 3 | `E` or `C` |
| Open Skill Menu | `K` |

---

### Gameplay Tips

- **Stamina Management:** Dashing and skills consume stamina. Wait for regeneration.
- **Skill Slots:** Match skills to slots based on their type (Type I, II, III).
- **Upgrade Strategy:** Failed upgrades give bonus probability for next attempt.
- **Double Jump:** Essential for reaching higher platforms and dodging.

---

### Cheat Commands (Debug Mode Only)

> ⚠️ **Warning:** These commands only work in debug builds!

| Key | Function |
|-----|----------|
| `F1` | Toggle cheat mode |
| `F2` | Toggle free camera (pause game, drag to move camera) |
| `K` | Open skill equip/upgrade/synthesis menu |
| `G` | Open reward selection screen |

---

### Skill Types

| Type | Slot | Examples |
|------|------|----------|
| Type I | Slot 1 (LMB) | BlinkSlash, FireBall, IceBall |
| Type II | Slot 2 (Q) | Slash, ThunderSlash, MultiShot |
| Type III | Slot 3 (E) | Heal, GreatHeal, Parry |

---

## 📦 Borrowed Contents

### Graphics & Visual Assets

| Asset Type | Source |
|------------|--------|
| Tilemap assets | [itch.io](https://itch.io) - Various creators |
| Background images | [itch.io](https://itch.io) - Various creators |
| Skill icons | [itch.io](https://itch.io) - Various creators |
| Character sprites | [itch.io](https://itch.io) - Various creators |
| UI elements | [itch.io](https://itch.io) - Various creators |

### Audio

| Audio Type | Source |
|------------|--------|
| Background music (BGM) | [Pixabay](https://pixabay.com) |
| Sound effects (SFX) | [Pixabay](https://pixabay.com) |

### Plugins & Addons

| Plugin | Description | Source |
|--------|-------------|--------|
| Audio Manager | Audio playback management | Godot Asset Library |
| Dialogue Manager | Dialogue system implementation | Godot Asset Library |

---

## 🤖 AI Tools Declaration

### AI Tool Usage in This Project

The following AI tools were utilized during the development of this project:

#### 1. Asset Generation

When suitable design assets were not available from existing resources, **generative AI** was used through prompt engineering to create:
- Custom map/environment designs
- Specific visual elements that matched the game's aesthetic
- UI components when needed

#### 2. Code Development

AI tools were used for:
- **Debugging assistance:** Identifying and resolving code issues
- **Code optimization suggestions:** Improving performance and readability
- **Documentation generation:** Creating code comments and documentation

#### 3. Scope of AI Usage

> ⚠️ **Important Notes:**
> - AI-generated assets were used **only when no suitable alternatives** were found on asset platforms
> - All AI-generated content was **reviewed and modified** by team members to fit the project
> - Core game logic and design decisions were **made by the development team**
> - AI was primarily used as a **supplementary tool**, not as the primary development method

---

## 📋 Technical Specifications

| Specification | Value |
|---------------|-------|
| Engine | Godot 4.5 |
| Resolution | 2560 x 1440 (16:9) |
| Rendering | Mobile renderer with pixel-perfect settings |
| Physics | Custom gravity (2500.0), physics interpolation enabled |

---

**Team 6 - Creative Media Programming 2025-2**

*This documentation was created as part of the final project requirements.*
