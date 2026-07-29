extends Node
## UISettingsManager — Global autoload singleton.
## Owns all UI visual style state across the entire game.
## Saves & loads from user://ui_settings.json automatically.

signal settings_changed

const SETTINGS_PATH: String = "user://ui_settings.json"

# ─────────────────────────────────────────────
# Enums — every independent style dimension
# ─────────────────────────────────────────────

enum TextStyle {
	CLEAN_WHITE,    ## 0: Crisp white, no shadow, ultra-minimal
	NEON_GLOW_CYAN, ## 1: Cyan glow drop-shadow + thin cyan outline
	RETRO_GOLD,     ## 2: Gold shimmer with warm amber drop-shadow
	MAGENTA_PULSE,  ## 3: Hot pink, heavy shadow, thick magenta outline
	GHOST_SLATE     ## 4: Muted stone-white, heavy dark blurred shadow
}

enum ButtonShapeStyle {
	GLASS_CAPSULE,    ## 0: 22px radius pill, translucent fill + glow border
	NEON_CYBER_BADGE, ## 1: 4px radius, thick 2px neon border, very dark fill
	MINIMAL_RING,     ## 2: 12px radius, near-transparent fill, outline only
	TRANSLUCENT_HALO, ## 3: 20px radius, 10% white fill, no visible border
	EMERALD_CRYSTAL,  ## 4: 4px angular, green frosted fill
	ROYAL_AMETHYST,   ## 5: 22px pill, deep violet gradient fill
	SOLAR_FLARE,      ## 6: 8px, warm amber-orange solid fill
	RETRO_PIXEL       ## 7: 0px (square), thick 3px stroke, minimal padding
}

enum LayoutStyle {
	CENTER_STACK, ## 0: Centered vertical column (classic)
	LEFT_RAIL,    ## 1: Left-edge vertical strip
	BOTTOM_PANEL, ## 2: Lower-center panel
	TOP_BAR       ## 3: Horizontal top bar
}

enum ShaderEffect {
	GRID_WAVE,       ## 0: Scrolling perspective grid (original)
	CYBER_HEXAGONS,  ## 1: Pulsing hex lattice (original)
	NEON_ORBS,       ## 2: Floating neon orb particles (original)
	CRT_SCANLINES,   ## 3: CRT monitor scanlines + vignette (NEW)
	STAR_WARP        ## 4: Radial shooting-star warp tunnel (NEW)
}

enum PauseButtonStyle {
	GLASS_CAPSULE, NEON_CYBER, MINIMAL_SLATE, TRANSPARENT_GLOW,
	EMERALD_CRYSTAL, ROYAL_AMETHYST, SOLAR_FLARE, RETRO_PIXEL
}

enum PanelStyle {
	FROSTED_GLASS, ULTRA_TRANSPARENT, NEON_HOLOGRAM, OBSIDIAN_SMOKE,
	SYNTHWAVE_VIOLET, EMERALD_MATRIX, AURORA_BOREALIS,
	MIDNIGHT_ROSE, SUNSET_HORIZON, DEEP_ABYSS
}

enum AnimType {
	BOUNCE_SPRING,  ## 0: Elastic back/spring ease-out pop, bouncy hover
	FAST_SNAPPY,    ## 1: Rapid cubic snap ease-out (0.12s)
	SMOOTH_GLIDE,   ## 2: Floating slide-in from offset, quad ease (0.35s)
	PULSE_ZOOM,     ## 3: Gentle zoom pulse with sine ease
	RETRO_STEPPED   ## 4: Instant stepped retro pop, zero smoothing
}

enum BounceType {
	TWEEN_PROCEDURAL,          ## 0: Code-driven tween loop
	ANIMATION_PLAYER_CLASSIC,  ## 1: AnimationPlayer classic bounce
	ANIMATION_PLAYER_HIGH_JUMP,## 2: AnimationPlayer high jump spin
	ANIMATION_PLAYER_DOUBLE_HOP## 3: AnimationPlayer double hop
}

# ─────────────────────────────────────────────
# Dev Mode
# ─────────────────────────────────────────────
const DEV_PIN: String = "1542"

# ─────────────────────────────────────────────
# Display name arrays (used by Style Lab UI)
# ─────────────────────────────────────────────

const TEXT_STYLE_NAMES: Array[String] = [
	"Clean White", "Neon Glow Cyan", "Retro Gold", "Magenta Pulse", "Ghost Slate"
]
const BUTTON_SHAPE_NAMES: Array[String] = [
	"Glass Capsule", "Neon Cyber Badge", "Minimal Ring",
	"Translucent Halo", "Emerald Crystal", "Royal Amethyst",
	"Solar Flare", "Retro Pixel"
]
const LAYOUT_NAMES: Array[String] = [
	"Centered Stack", "Left Rail", "Bottom Panel", "Top Bar"
]
const SHADER_NAMES: Array[String] = [
	"Grid Wave", "Cyber Hexagons", "Neon Orbs", "CRT Scanlines", "Star Warp"
]
const PAUSE_BTN_NAMES: Array[String] = [
	"Glass Capsule", "Neon Cyber Badge", "Minimal Slate Ring",
	"Translucent Halo", "Emerald Crystal", "Royal Amethyst",
	"Solar Flare", "Retro Pixel"
]
const PANEL_NAMES: Array[String] = [
	"Frosted Glass", "Ultra Transparent", "Neon Hologram",
	"Obsidian Smoke", "Synthwave Violet", "Emerald Matrix",
	"Aurora Borealis", "Midnight Rose", "Sunset Horizon", "Deep Abyss"
]
const ANIMATION_NAMES: Array[String] = [
	"Bounce & Spring", "Fast & Snappy", "Smooth Glide", "Pulse & Zoom", "Retro Stepped"
]
const BOUNCE_NAMES: Array[String] = [
	"Tween Procedural", "Classic Bounce", "High Jump Spin", "Double Hop"
]

# ─────────────────────────────────────────────
# Current values (runtime state)
# ─────────────────────────────────────────────

var text_style: int        = TextStyle.NEON_GLOW_CYAN
var button_shape: int      = ButtonShapeStyle.GLASS_CAPSULE
var layout_style: int      = LayoutStyle.CENTER_STACK
var shader_effect: int     = ShaderEffect.GRID_WAVE
var pause_btn_style: int   = PauseButtonStyle.GLASS_CAPSULE
var panel_style: int       = PanelStyle.FROSTED_GLASS
var anim_style: int        = AnimType.BOUNCE_SPRING
var bounce_style: int      = BounceType.ANIMATION_PLAYER_CLASSIC
var dev_mode_unlocked: bool = false

const DEFAULTS := {
	"text_style":      1,
	"button_shape":    0,
	"layout_style":    0,
	"shader_effect":   0,
	"pause_btn_style": 0,
	"panel_style":     0,
	"anim_style":      0,
	"bounce_style":    1
}

# ─────────────────────────────────────────────
# Lifecycle
# ─────────────────────────────────────────────

func _ready() -> void:
	load_settings()


# ─────────────────────────────────────────────
# JSON Persistence
# ─────────────────────────────────────────────

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		save_settings()
		return

	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if not file:
		return

	var parsed = JSON.parse_string(file.get_as_text())
	file.close()

	if not parsed is Dictionary:
		return

	text_style      = _clamp_enum(parsed.get("text_style",      DEFAULTS["text_style"]),      TextStyle.size())
	button_shape    = _clamp_enum(parsed.get("button_shape",    DEFAULTS["button_shape"]),    ButtonShapeStyle.size())
	layout_style    = _clamp_enum(parsed.get("layout_style",    DEFAULTS["layout_style"]),    LayoutStyle.size())
	shader_effect   = _clamp_enum(parsed.get("shader_effect",   DEFAULTS["shader_effect"]),   ShaderEffect.size())
	pause_btn_style = _clamp_enum(parsed.get("pause_btn_style", DEFAULTS["pause_btn_style"]), PauseButtonStyle.size())
	panel_style     = _clamp_enum(parsed.get("panel_style",     DEFAULTS["panel_style"]),     PanelStyle.size())
	anim_style      = _clamp_enum(parsed.get("anim_style",      DEFAULTS["anim_style"]),      AnimType.size())
	bounce_style    = _clamp_enum(parsed.get("bounce_style",    DEFAULTS["bounce_style"]),    BounceType.size())
	dev_mode_unlocked = bool(parsed.get("dev_mode_unlocked", false))


func save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if not file:
		return
	file.store_string(JSON.stringify({
		"text_style":      text_style,
		"button_shape":    button_shape,
		"layout_style":    layout_style,
		"shader_effect":   shader_effect,
		"pause_btn_style": pause_btn_style,
		"panel_style":     panel_style,
		"anim_style":      anim_style,
		"bounce_style":    bounce_style,
		"dev_mode_unlocked": dev_mode_unlocked
	}, "\t"))
	file.close()


func reset_to_defaults() -> void:
	text_style      = DEFAULTS["text_style"]
	button_shape    = DEFAULTS["button_shape"]
	layout_style    = DEFAULTS["layout_style"]
	shader_effect   = DEFAULTS["shader_effect"]
	pause_btn_style = DEFAULTS["pause_btn_style"]
	panel_style     = DEFAULTS["panel_style"]
	anim_style      = DEFAULTS["anim_style"]
	bounce_style    = DEFAULTS["bounce_style"]
	save_settings()
	settings_changed.emit()


func unlock_dev_mode() -> void:
	dev_mode_unlocked = true
	save_settings()



## Generic setter: sets a property, saves JSON, emits settings_changed.
func set_and_save(property: String, value: int) -> void:
	set(property, value)
	save_settings()
	settings_changed.emit()


# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────

func _clamp_enum(raw, count: int) -> int:
	return clampi(int(raw), 0, count - 1)


## Returns shape parameters for the current button_shape setting.
## Used by both HUD and MainMenu to apply button shape without touching color.
func get_button_shape_params() -> Dictionary:
	match button_shape:
		ButtonShapeStyle.GLASS_CAPSULE:
			return {radius = 22, border = 1.0, alpha_mul = 1.0, letter_spacing = 0}
		ButtonShapeStyle.NEON_CYBER_BADGE:
			return {radius = 4,  border = 2.0, alpha_mul = 1.0, letter_spacing = 2}
		ButtonShapeStyle.MINIMAL_RING:
			return {radius = 12, border = 1.5, alpha_mul = 0.06, letter_spacing = 1}
		ButtonShapeStyle.TRANSLUCENT_HALO:
			return {radius = 20, border = 0.0, alpha_mul = 0.12, letter_spacing = 0}
		ButtonShapeStyle.EMERALD_CRYSTAL:
			return {radius = 4,  border = 1.5, alpha_mul = 1.0, letter_spacing = 1}
		ButtonShapeStyle.ROYAL_AMETHYST:
			return {radius = 24, border = 1.0, alpha_mul = 1.0, letter_spacing = 0}
		ButtonShapeStyle.SOLAR_FLARE:
			return {radius = 8,  border = 1.5, alpha_mul = 1.0, letter_spacing = 2}
		ButtonShapeStyle.RETRO_PIXEL:
			return {radius = 0,  border = 3.0, alpha_mul = 1.0, letter_spacing = 3}
	return {radius = 10, border = 1.0, alpha_mul = 1.0, letter_spacing = 0}


## Returns all text rendering parameters for the current text_style.
func get_text_style_params() -> Dictionary:
	match text_style:
		TextStyle.CLEAN_WHITE:
			return {
				title_color  = Color(1.0, 1.0, 1.0),
				btn_color    = Color(0.9, 0.95, 1.0),
				shadow_color = Color(0, 0, 0, 0),
				shadow_x = 0, shadow_y = 0,
				outline_color = Color(0, 0, 0, 0),
				outline_size = 0
			}
		TextStyle.NEON_GLOW_CYAN:
			return {
				title_color  = Color(1.0, 1.0, 1.0),
				btn_color    = Color(0.88, 0.97, 1.0),
				shadow_color = Color(0.0, 0.85, 1.0, 0.75),
				shadow_x = 0, shadow_y = 2,
				outline_color = Color(0.0, 0.7, 1.0, 0.4),
				outline_size = 1
			}
		TextStyle.RETRO_GOLD:
			return {
				title_color  = Color(1.0, 0.88, 0.2),
				btn_color    = Color(1.0, 0.85, 0.3),
				shadow_color = Color(0.85, 0.35, 0.0, 0.8),
				shadow_x = 2, shadow_y = 2,
				outline_color = Color(0.6, 0.35, 0.0, 0.5),
				outline_size = 1
			}
		TextStyle.MAGENTA_PULSE:
			return {
				title_color  = Color(1.0, 0.95, 1.0),
				btn_color    = Color(1.0, 0.9, 1.0),
				shadow_color = Color(1.0, 0.1, 0.65, 0.85),
				shadow_x = 0, shadow_y = 3,
				outline_color = Color(1.0, 0.2, 0.7, 0.55),
				outline_size = 2
			}
		TextStyle.GHOST_SLATE:
			return {
				title_color  = Color(0.72, 0.76, 0.85),
				btn_color    = Color(0.68, 0.72, 0.8),
				shadow_color = Color(0.0, 0.0, 0.0, 0.72),
				shadow_x = 1, shadow_y = 1,
				outline_color = Color(0, 0, 0, 0),
				outline_size = 0
			}
	return {
		title_color = Color.WHITE, btn_color = Color.WHITE,
		shadow_color = Color(0,0,0,0), shadow_x = 0, shadow_y = 0,
		outline_color = Color(0,0,0,0), outline_size = 0
	}


## Returns tween animation parameters for current anim_style setting.
func get_animation_params() -> Dictionary:
	match anim_style:
		AnimType.BOUNCE_SPRING:
			return {
				duration = 0.28,
				trans_type = Tween.TRANS_BACK,
				ease_type = Tween.EASE_OUT,
				hover_scale = Vector2(1.12, 1.12),
				initial_scale = Vector2(0.6, 0.6)
			}
		AnimType.FAST_SNAPPY:
			return {
				duration = 0.12,
				trans_type = Tween.TRANS_CUBIC,
				ease_type = Tween.EASE_OUT,
				hover_scale = Vector2(1.05, 1.05),
				initial_scale = Vector2(0.9, 0.9)
			}
		AnimType.SMOOTH_GLIDE:
			return {
				duration = 0.35,
				trans_type = Tween.TRANS_QUAD,
				ease_type = Tween.EASE_OUT,
				hover_scale = Vector2(1.08, 1.08),
				initial_scale = Vector2(0.85, 0.85)
			}
		AnimType.PULSE_ZOOM:
			return {
				duration = 0.45,
				trans_type = Tween.TRANS_SINE,
				ease_type = Tween.EASE_IN_OUT,
				hover_scale = Vector2(1.15, 1.15),
				initial_scale = Vector2(0.7, 0.7)
			}
		AnimType.RETRO_STEPPED:
			return {
				duration = 0.05,
				trans_type = Tween.TRANS_LINEAR,
				ease_type = Tween.EASE_IN,
				hover_scale = Vector2(1.0, 1.0),
				initial_scale = Vector2(1.0, 1.0)
			}

	return {
		duration = 0.25,
		trans_type = Tween.TRANS_BACK,
		ease_type = Tween.EASE_OUT,
		hover_scale = Vector2(1.1, 1.1),
		initial_scale = Vector2(0.8, 0.8)
	}
