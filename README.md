# De-Bug

**A 2D Action Platformer Game**

*2025-2 Creative Media Programming - Team 6 Final Godot Project*

---

## Table of Contents

1. [Game Overview](#game-overview)
2. [Project Architecture](#project-architecture)
3. [Directory Structure](#directory-structure)
4. [Core Systems](#core-systems)
5. [Scenes Documentation](#scenes-documentation)
6. [Scripts Documentation](#scripts-documentation)
7. [User Manual](#user-manual)
8. [Borrowed Contents](#borrowed-contents)
9. [AI Tools Declaration](#ai-tools-declaration)

---

## Game Overview

**De-Bug** is a 2D action platformer game where players progress through stages by collecting various "Skill Fragments." The core mechanics revolve around:

- **Skill Collection**: Gather skill fragments from cleared stages
- **Skill Enhancement**: Upgrade skills using collected fragments
- **Skill Synthesis**: Combine fragments to create new skills
- **Strategic Slot Management**: Manage a limited 3-skill slot system to adapt to different combat situations

### Game Structure (Chapter 1)

| Stage | Name | Description |
|-------|------|-------------|
| Stage 1 | Pixel City | Tutorial stage - Learn basic controls and mechanics |
| Stage 2 | Data Jungle | Forest-themed environment with new enemy types |
| Stage 3 | Forgotten Memory Cemetery | Graveyard setting with traps and hazards |
| Stage 4 | Citadel of the Core | Final approach to the boss |
| Boss Stage | Corrupt Core | Final boss encounter |

---

## Project Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         AUTOLOAD (Singletons)                   │
├─────────────────┬─────────────────┬─────────────────┬───────────┤
│  GameManager    │ InventoryManager│  EffectManager  │ Scene     │
│  (State Machine)│ (Skills/Items)  │  (VFX/SFX)      │ Transition│
└────────┬────────┴────────┬────────┴────────┬────────┴───────────┘
         │                 │                 │
         ▼                 ▼                 ▼
┌─────────────────────────────────────────────────────────────────┐
│               WORLD (Stage 1 ~ 4 / Boss Stage)                  │
│        - Stage management, Portal system, Enemy tracking        │
└─────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│                              ACTORS                             │
├─────────────────────────────┬───────────────────────────────────┤
│         PLAYER              │              ENEMIES              │
│  - Movement & Input         │  - BaseEnemy (Abstract)           │
│  - Skill Casting            │  - Common Enemies (Virus types)   │
│  - Health & Stamina         │  - Middle Bosses                  │
│  - Equipment Slots          │  - Final Boss (CorruptCOre)       │
└─────────────────────────────┴───────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│                          SKILL SYSTEM                           │
├─────────────────┬─────────────────┬─────────────────────────────┤
│   BaseSkill     │  SkillInstance  │     Individual Skills       │
│   (Abstract)    │  (Data Class)   │  (FireBall, Heal, Slash...) │
└─────────────────┴─────────────────┴─────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│                           UI SYSTEM                             │
├─────────────────┬─────────────────┬─────────────────────────────┤
│    SkillUI      │   SkillGetUI    │      HUD Components         │
│ (Equip/Upgrade) │ (Reward Screen) │  (Health, Stamina, Skills)  │
└─────────────────┴─────────────────┴─────────────────────────────┘
```

### Design Patterns Used

- **Singleton Pattern**: Autoload managers (GameManager, InventoryManager, EffectManager)
- **State Machine**: Player and enemy state management
- **Observer Pattern**: Signal-based event system for enemy deaths, skill events
- **Component Pattern**: Modular skill system with BaseSkill inheritance

---

## Directory Structure

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
│   │   └── Boss/                   # Final boss
│   │       ├── fly_boss.gd         # Main boss controller
│   │       ├── boss_fire.gd        # Fire attack pattern
│   │       ├── boss_laser.gd       # Laser attack pattern
│   │       ├── boss_meteor.gd      # Meteor attack pattern
│   │       ├── boss_virus.gd       # Summon attack pattern
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
├── world/                          # World and stage management
│   ├── world.gd/tscn               # Base world class
│   ├── StartScreen/                # Title screen
│   │   ├── start_screen.gd/tscn
│   │   └── startScreenBg.gd
│   └── Option/                     # Options menu
│       └── option.gd/tscn
│
├── testScenes_SIC/                 # Stage implementations
│   ├── Stage1/Stage1.gd            # Tutorial stage (Pixel City)
│   ├── Stage2/Stage2.gd            # Data Jungle
│   ├── Stage3/Stage3.gd/tscn       # Forgotten Memory Cemetery
│   ├── Stage4/Stage4.gd/tscn       # Citadel of the Core
│   ├── StageBoss/stage_boss.gd     # Boss stage
│   ├── dialogue/                   # Dialogue files
│   ├── map_camera.gd               # Camera controller
│   ├── player_anim.gd              # Player animation helper
│   └── portal_anim.gd              # Portal animation
│
├── effects/                        # Visual effects
│   ├── HitEffect.gd/tscn           # Hit particle effect
│   └── hit_flash.gdshader          # Flash shader for damage
│
├── autoload/                       # Autoload scripts
│   └── SceneTransition.gd/tscn     # Scene transition effects
│
├── addons/                         # Third-party plugins
│   ├── audio_manager/              # Audio management plugin
│   └── dialogue_manager/           # Dialogue system plugin
│
├── graphics/                       # Visual assets
│   ├── Actors/                     # Character sprites
│   └── resource/                   # Stage-specific resources
│
├── Sounds/                         # Audio assets
│   ├── bgm/                        # Background music
│   └── effects/                    # Sound effects
│
├── Block/                          # Environment blocks
│   └── wall.tscn                   # Wall/platform tiles
│
├── GameManager.gd                  # Global game state manager
├── InventoryManager.gd             # Skill inventory system
├── EffectManager.gd                # Visual/audio effects manager
├── SkillInstance.gd                # Skill data resource class
├── SkillUpgradeData.gd             # Skill upgrade configuration
└── project.godot                   # Godot project configuration
```

---

## Core Systems

### 1. GameManager (Autoload)

**File**: `GameManager.gd`

Manages the global game state using a state machine pattern.

**States**:
- `IDLE`: Player is stationary
- `MOVE`: Player is moving
- `DASH`: Player is dashing (invincible)
- `SKILL_CASTING`: Player is using a skill

**Features**:
- Cheat mode toggle (debug builds only)
- Free camera mode for development
- Global state access from any script

### 2. InventoryManager (Autoload)

**File**: `InventoryManager.gd`

Handles all skill-related data management.

**Features**:
- Skill database loading from directory
- Player inventory management
- Equipment slot tracking (3 slots)
- Skill upgrade system with probability-based success
- Skill synthesis (combining skills)

**Key Methods**:
- `add_skill_to_inventory()`: Add skill to player inventory
- `remove_skill_from_inventory()`: Remove skill from inventory
- `attempt_upgrade()`: Try to upgrade a skill with another
- `get_random_skill_path()`: Get random skill for rewards

### 3. EffectManager (Autoload)

**File**: `EffectManager.gd`

Centralizes all visual and audio effects.

**Features**:
- Screen shake effects
- Screen flash effects (single and multi-flash)
- Hit particle spawning
- Shader-based hit flash on sprites

### 4. SceneTransition (Autoload)

**File**: `autoload/SceneTransition.gd`

Handles smooth scene transitions with fade effects.

**Methods**:
- `fade_to_scene()`: Transition with fade out/in
- `fade_out()` / `fade_in()`: Individual fade controls

---

## Scenes Documentation

### Player Scene (`Actors/Player/player.tscn`)

The main playable character with:
- CharacterBody2D for physics
- AnimatedSprite2D for animations
- Camera2D with stage limits
- Collision shapes for hitbox
- Timer nodes for dash cooldown, i-frames
- Skill slot containers (3 slots)

### Enemy Scenes

**Common Enemies**:
- `virus.tscn`: Ground-based melee enemy
- `FlyEnemy.tscn`: Flying enemy with patrol patterns
- `HoverEnemy.tscn`: Stationary hovering enemy
- `RangeVirus.tscn`: Ranged attack enemy

**Middle Bosses**:
- `TutorialBoss.tscn`: Stage 1 mini-boss
- `JungleBoss.tscn`: Stage 2 mini-boss
- `FlyBoss.tscn`: Final boss with multiple attack patterns

**Final Boss(Corrupt Core)**:
- `BossMeteor.tscn`, `BossLaser.tscn`, `BossFire.tscn`: Boss pattern components

### UI Scenes

- `SkillUI.tscn`: Equipment, upgrade, and synthesis tabs
- `SkillGetUI.tscn`: Post-stage reward selection
- `SkillHudIcon.tscn`: Real-time skill cooldown display

---

## Scripts Documentation

### Player System

#### player.gd
Main player controller handling:
- Movement (WASD + Arrow keys)
- Jumping (double jump supported)
- Dashing (with stamina cost)
- Skill casting (3 skill slots)
- Health/lives management
- Invincibility frames

**Key Properties**:
```gdscript
@export var max_speed: float = 400.0
@export var jump_velocity: float = -600.0
@export var max_jumps: int = 2
@export var dash_speed: float = 1200.0
@export var max_lives: int = 3
@export var max_stamina: float = 100.0
```

### Enemy System

#### BaseEnemy.gd
Abstract base class for all enemies providing:
- Health management
- Damage handling with i-frames
- Death signal emission
- Boss HP bar support
- Hit flash shader integration

**Attack Patterns**:
1. Spread shot (3-way bullets)
2. Minion summoning
3. Orbital bullet pattern
4. Bombing run with meteors

### Skill System

#### BaseSkill.gd
Abstract base for all skills:
- Skill properties (name, description, icon)
- Cooldown management
- Stamina cost
- Sound effect support
- Level-based upgrade system

#### SkillInstance.gd
Resource class storing:
- Skill path reference
- Current level
- Upgrade bonus accumulation

### UI System

#### SkillUI.gd
Three-tab interface:
1. **Equipment Tab**: Drag-drop skill equipping
2. **Upgrade Tab**: Skill enhancement (same skill + same skill)
3. **Synthesis Tab**: Combine two skills for random new skill

#### SkillGetUI.gd
Reward screen after stage completion:
- Displays 3 random skill choices
- Animated selection effects
- Skip option available

---

## User Manual

### Controls

| Action | Key(s) |
|--------|--------|
| Move Left | `A` or `←` |
| Move Right | `D` or `→` |
| Jump | `W` or `↑` |
| Double Jump | Press jump again while airborne |
| Dash | `Shift` |
| Skill Slot 1 | `Left Mouse Click` or `Z` |
| Skill Slot 2 | `Q` or `X` |
| Skill Slot 3 | `E` or `C` |
| Open Skill Menu | `K` |
| Pause/Options | `ESC` |

### Gameplay Tips

1. **Stamina Management**: Dashing and skills consume stamina. Wait for regeneration.
2. **Skill Slots**: Match skills to slots based on their type (Type I, II, III).
3. **Upgrade Strategy**: Failed upgrades give bonus probability for next attempt.
4. **Double Jump**: Essential for reaching higher platforms and dodging.

### Cheat Commands (Debug Mode Only)

| Key | Function |
|-----|----------|
| `F1` | Toggle cheat mode |
| `F2` | Toggle free camera (pause game, drag to move camera) |
| `K` | Open skill equip/upgrade/synthesis menu |
| `G` | Open reward selection screen |

### Skill Types

| Type | Slot | Examples |
|------|------|----------|
| Type I | Slot 1 (LMB) | BlinkSlash, FireBall, IceBall |
| Type II | Slot 2 (Q) | Slash, ThunderSlash, MultiShot |
| Type III | Slot 3 (E) | Heal, GreatHeal, Parry |

---

## Borrowed Contents

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

## AI Tools Declaration

### AI Tool Usage in This Project

The following AI tools were utilized during the development of this project:

#### 1. Asset Generation

When suitable design assets were not available from existing resources, **generative AI** was used through prompt engineering to create:
- Custom map/environment designs
- Specific visual elements that matched the game's aesthetic
- UI components when needed

#### 2. Code Development

AI tools were used for:
- **Debugging assistance**: Identifying and resolving code issues
- **Code optimization suggestions**: Improving performance and readability
- **Documentation generation**: Creating code comments and documentation

#### 3. Scope of AI Usage

- AI-generated assets were used only when no suitable alternatives were found on asset platforms
- All AI-generated content was reviewed and modified by team members to fit the project
- Core game logic and design decisions were made by the development team
- AI was primarily used as a supplementary tool, not as the primary development method

---

## Technical Specifications

- **Engine**: Godot 4.5
- **Resolution**: 2560 x 1440 (16:9)
- **Rendering**: Mobile renderer with pixel-perfect settings
- **Physics**: Custom gravity (2500.0), physics interpolation enabled

---

## Credits

**Team 6 - Creative Media Programming 2025-2**

---

*This documentation was created as part of the final project requirements.*
