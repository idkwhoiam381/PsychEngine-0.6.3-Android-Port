package flixel;

import flash.display.Graphics;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.math.FlxVelocity;
import flixel.tile.FlxBaseTilemap;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxDirectionFlags;
import flixel.util.FlxPath;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxStringUtil;

/**
 * This is the base class for most of the display objects (`FlxSprite`, `FlxText`, etc).
 * It includes some basic attributes about game objects, basic state information,
 * sizes, scrolling, and basic physics and motion.
 */
class FlxObjectOld extends FlxBasic
{
	/**
	 * Default value for `FlxObjectOld`'s `pixelPerfectPosition` var.
	 */
	public static var defaultPixelPerfectPosition:Bool = false;

	/**
	 * This value dictates the maximum number of pixels two objects have to intersect
	 * before collision stops trying to separate them.
	 * Don't modify this unless your objects are passing through each other.
	 */
	public static var SEPARATE_BIAS:Float = 4;

	/**
	 * Generic value for "left". Used by `facing`, `allowCollisions`, and `touching`.
	 * Note: This exists for backwards compatibility, prefer using `FlxDirectionFlags.LEFT` directly.
	 */
	public static inline var LEFT = FlxDirectionFlags.LEFT;

	/**
	 * Generic value for "right". Used by `facing`, `allowCollisions`, and `touching`.
	 * Note: This exists for backwards compatibility, prefer using `FlxDirectionFlags.RIGHT` directly.
	 */
	public static inline var RIGHT = FlxDirectionFlags.RIGHT;

	/**
	 * Generic value for "up". Used by `facing`, `allowCollisions`, and `touching`.
	 * Note: This exists for backwards compatibility, prefer using `FlxDirectionFlags.UP` directly.
	 */
	public static inline var UP = FlxDirectionFlags.UP;

	/**
	 * Generic value for "down". Used by `facing`, `allowCollisions`, and `touching`.
	 * Note: This exists for backwards compatibility, prefer using `FlxDirectionFlags.DOWN` directly.
	 */
	public static inline var DOWN = FlxDirectionFlags.DOWN;

	/**
	 * Special-case constant meaning no collisions, used mainly by `allowCollisions` and `touching`.
	 * Note: This exists for backwards compatibility, prefer using `FlxDirectionFlags.NONE` directly.
	 */
	public static inline var NONE = FlxDirectionFlags.NONE;

	/**
	 * Special-case constant meaning up, used mainly by `allowCollisions` and `touching`.
	 * Note: This exists for backwards compatibility, prefer using `FlxDirectionFlags.CEILING` directly.
	 */
	public static inline var CEILING = FlxDirectionFlags.CEILING;

	/**
	 * Special-case constant meaning down, used mainly by `allowCollisions` and `touching`.
	 * Note: This exists for backwards compatibility, prefer using `FlxDirectionFlags.FLOOR` directly.
	 */
	public static inline var FLOOR = FlxDirectionFlags.FLOOR;

	/**
	 * Special-case constant meaning only the left and right sides, used mainly by `allowCollisions` and `touching`.
	 * Note: This exists for backwards compatibility, prefer using `FlxDirectionFlags.WALL` directly.
	 */
	public static inline var WALL = FlxDirectionFlags.WALL;

	/**
	 * Special-case constant meaning any direction, used mainly by `allowCollisions` and `touching`.
	 * Note: This exists for backwards compatibility, prefer using `FlxDirectionFlags.ANY` directly.
	 */
	public static inline var ANY = FlxDirectionFlags.ANY;

	@:noCompletion
	static var _firstSeparateFlxRect:FlxRect = FlxRect.get();
	@:noCompletion
	static var _secondSeparateFlxRect:FlxRect = FlxRect.get();

	/**
	 * The main collision resolution function in Flixel.
	 *
	 * @param   Object1   Any `FlxObjectOld`.
	 * @param   Object2   Any other `FlxObjectOld`.
	 * @return  Whether the objects in fact touched and were separated.
	 */
	public static function separate(Object1:FlxObjectOld, Object2:FlxObjectOld):Bool
	{
		var separatedX:Bool = separateX(Object1, Object2);
		var separatedY:Bool = separateY(Object1, Object2);
		return separatedX || separatedY;
	}

	/**
	 * Similar to `separate()`, but only checks whether any overlap is found and updates
	 * the `touching` flags of the input objects, but no separation is performed.
	 *
	 * @param   Object1   Any `FlxObjectOld`.
	 * @param   Object2   Any other `FlxObjectOld`.
	 * @return  Whether the objects in fact touched.
	 */
	public static function updateTouchingFlags(Object1:FlxObjectOld, Object2:FlxObjectOld):Bool
	{
		var touchingX:Bool = updateTouchingFlagsX(Object1, Object2);
		var touchingY:Bool = updateTouchingFlagsY(Object1, Object2);
		return touchingX || touchingY;
	}

	/**
	 * Internal function that computes overlap among two objects on the X axis. It also updates the `touching` variable.
	 * `checkMaxOverlap` is used to determine whether we want to exclude (therefore check) overlaps which are
	 * greater than a certain maximum (linked to `SEPARATE_BIAS`). Default is `true`, handy for `separateX` code.
	 */
	@:noCompletion
	static function computeOverlapX(Object1:FlxObjectOld, Object2:FlxObjectOld, checkMaxOverlap:Bool = true):Float
	{
		var overlap:Float = 0;
		// First, get the two object deltas
		var obj1delta:Float = Object1.x - Object1.last.x;
		var obj2delta:Float = Object2.x - Object2.last.x;

		if (obj1delta != obj2delta)
		{
			// Check if the X hulls actually overlap
			var obj1deltaAbs:Float = (obj1delta > 0) ? obj1delta : -obj1delta;
			var obj2deltaAbs:Float = (obj2delta > 0) ? obj2delta : -obj2delta;

			var obj1rect:FlxRect = _firstSeparateFlxRect.set(Object1.x - ((obj1delta > 0) ? obj1delta : 0), Object1.last.y, Object1.width + obj1deltaAbs,
				Object1.height);
			var obj2rect:FlxRect = _secondSeparateFlxRect.set(Object2.x - ((obj2delta > 0) ? obj2delta : 0), Object2.last.y, Object2.width + obj2deltaAbs,
				Object2.height);

			if ((obj1rect.x + obj1rect.width > obj2rect.x)
				&& (obj1rect.x < obj2rect.x + obj2rect.width)
				&& (obj1rect.y + obj1rect.height > obj2rect.y)
				&& (obj1rect.y < obj2rect.y + obj2rect.height))
			{
				var maxOverlap:Float = checkMaxOverlap ? (obj1deltaAbs + obj2deltaAbs + SEPARATE_BIAS) : 0;

				// If they did overlap (and can), figure out by how much and flip the corresponding flags
				if (obj1delta > obj2delta)
				{
					overlap = Object1.x + Object1.width - Object2.x;
					if ((checkMaxOverlap && (overlap > maxOverlap))
						|| ((Object1.allowCollisions & RIGHT) == 0)
						|| ((Object2.allowCollisions & LEFT) == 0))
					{
						overlap = 0;
					}
					else
					{
						Object1.touching |= RIGHT;
						Object2.touching |= LEFT;
					}
				}
				else if (obj1delta < obj2delta)
				{
					overlap = Object1.x - Object2.width - Object2.x;
					if ((checkMaxOverlap && (-overlap > maxOverlap))
						|| ((Object1.allowCollisions & LEFT) == 0)
						|| ((Object2.allowCollisions & RIGHT) == 0))
					{
						overlap = 0;
					}
					else
					{
						Object1.touching |= LEFT;
						Object2.touching |= RIGHT;
					}
				}
			}
		}
		return overlap;
	}

	/**
	 * The X-axis component of the object separation process.
	 *
	 * @param   Object1   Any `FlxObjectOld`.
	 * @param   Object2   Any other `FlxObjectOld`.
	 * @return  Whether the objects in fact touched and were separated along the X axis.
	 */
	public static function separateX(Object1:FlxObjectOld, Object2:FlxObjectOld):Bool
	{
		// can't separate two immovable objects
		var obj1immovable:Bool = Object1.immovable;
		var obj2immovable:Bool = Object2.immovable;
		if (obj1immovable && obj2immovable)
		{
			return false;
		}

		// If one of the objects is a tilemap, just pass it off.
		if (Object1.flixelType == TILEMAP)
		{
			var tilemap:FlxBaseTilemap<Dynamic> = cast Object1;
			return tilemap.overlapsWithCallback(Object2, separateX);
		}
		if (Object2.flixelType == TILEMAP)
		{
			var tilemap:FlxBaseTilemap<Dynamic> = cast Object2;
			return tilemap.overlapsWithCallback(Object1, separateX, true);
		}

		var overlap:Float = computeOverlapX(Object1, Object2);
		// Then adjust their positions and velocities accordingly (if there was any overlap)
		if (overlap != 0)
		{
			var obj1v:Float = Object1.velocity.x;
			var obj2v:Float = Object2.velocity.x;

			if (!obj1immovable && !obj2immovable)
			{
				overlap *= 0.5;
				Object1.x = Object1.x - overlap;
				Object2.x += overlap;

				var obj1velocity:Float = Math.sqrt((obj2v * obj2v * Object2.mass) / Object1.mass) * ((obj2v > 0) ? 1 : -1);
				var obj2velocity:Float = Math.sqrt((obj1v * obj1v * Object1.mass) / Object2.mass) * ((obj1v > 0) ? 1 : -1);
				var average:Float = (obj1velocity + obj2velocity) * 0.5;
				obj1velocity -= average;
				obj2velocity -= average;
				Object1.velocity.x = average + obj1velocity * Object1.elasticity;
				Object2.velocity.x = average + obj2velocity * Object2.elasticity;
			}
			else if (!obj1immovable)
			{
				Object1.x = Object1.x - overlap;
				Object1.velocity.x = obj2v - obj1v * Object1.elasticity;
			}
			else if (!obj2immovable)
			{
				Object2.x += overlap;
				Object2.velocity.x = obj1v - obj2v * Object2.elasticity;
			}
			return true;
		}

		return false;
	}

	/**
	 * Checking overlap and updating `touching` variables, X-axis part used by `updateTouchingFlags`.
	 *
	 * @param   Object1   Any `FlxObjectOld`.
	 * @param   Object2   Any other `FlxObjectOld`.
	 * @return  Whether the objects in fact touched along the X axis.
	 */
	public static function updateTouchingFlagsX(Object1:FlxObjectOld, Object2:FlxObjectOld):Bool
	{
		// If one of the objects is a tilemap, just pass it off.
		if (Object1.flixelType == TILEMAP)
		{
			var tilemap:FlxBaseTilemap<Dynamic> = cast Object1;
			return tilemap.overlapsWithCallback(Object2, updateTouchingFlagsX);
		}
		if (Object2.flixelType == TILEMAP)
		{
			var tilemap:FlxBaseTilemap<Dynamic> = cast Object2;
			return tilemap.overlapsWithCallback(Object1, updateTouchingFlagsX, true);
		}
		// Since we are not separating, always return any amount of overlap => false as last parameter
		return computeOverlapX(Object1, Object2, false) != 0;
	}

	/**
	 * Internal function that computes overlap among two objects on the Y axis. It also updates the `touching` variable.
	 * `checkMaxOverlap` is used to determine whether we want to exclude (therefore check) overlaps which are
	 * greater than a certain maximum (linked to `SEPARATE_BIAS`). Default is `true`, handy for `separateY` code.
	 */
	@:noCompletion
	static function computeOverlapY(Object1:FlxObjectOld, Object2:FlxObjectOld, checkMaxOverlap:Bool = true):Float
	{
		var overlap:Float = 0;
		// First, get the two object deltas
		var obj1delta:Float = Object1.y - Object1.last.y;
		var obj2delta:Float = Object2.y - Object2.last.y;

		if (obj1delta != obj2delta)
		{
			// Check if the Y hulls actually overlap
			var obj1deltaAbs:Float = (obj1delta > 0) ? obj1delta : -obj1delta;
			var obj2deltaAbs:Float = (obj2delta > 0) ? obj2delta : -obj2delta;

			var obj1rect:FlxRect = _firstSeparateFlxRect.set(Object1.x, Object1.y - ((obj1delta > 0) ? obj1delta : 0), Object1.width,
				Object1.height + obj1deltaAbs);
			var obj2rect:FlxRect = _secondSeparateFlxRect.set(Object2.x, Object2.y - ((obj2delta > 0) ? obj2delta : 0), Object2.width,
				Object2.height + obj2deltaAbs);

			if ((obj1rect.x + obj1rect.width > obj2rect.x)
				&& (obj1rect.x < obj2rect.x + obj2rect.width)
				&& (obj1rect.y + obj1rect.height > obj2rect.y)
				&& (obj1rect.y < obj2rect.y + obj2rect.height))
			{
				var maxOverlap:Float = checkMaxOverlap ? (obj1deltaAbs + obj2deltaAbs + SEPARATE_BIAS) : 0;

				// If they did overlap (and can), figure out by how much and flip the corresponding flags
				if (obj1delta > obj2delta)
				{
					overlap = Object1.y + Object1.height - Object2.y;
					if ((checkMaxOverlap && (overlap > maxOverlap))
						|| ((Object1.allowCollisions & DOWN) == 0)
						|| ((Object2.allowCollisions & UP) == 0))
					{
						overlap = 0;
					}
					else
					{
						Object1.touching |= DOWN;
						Object2.touching |= UP;
					}
				}
				else if (obj1delta < obj2delta)
				{
					overlap = Object1.y - Object2.height - Object2.y;
					if ((checkMaxOverlap && (-overlap > maxOverlap))
						|| ((Object1.allowCollisions & UP) == 0)
						|| ((Object2.allowCollisions & DOWN) == 0))
					{
						overlap = 0;
					}
					else
					{
						Object1.touching |= UP;
						Object2.touching |= DOWN;
					}
				}
			}
		}
		return overlap;
	}

	/**
	 * The Y-axis component of the object separation process.
	 *
	 * @param   Object1   Any `FlxObjectOld`.
	 * @param   Object2   Any other `FlxObjectOld`.
	 * @return  Whether the objects in fact touched and were separated along the Y axis.
	 */
	public static function separateY(Object1:FlxObjectOld, Object2:FlxObjectOld):Bool
	{
		// can't separate two immovable objects
		var obj1immovable:Bool = Object1.immovable;
		var obj2immovable:Bool = Object2.immovable;
		if (obj1immovable && obj2immovable)
		{
			return false;
		}

		// If one of the objects is a tilemap, just pass it off.
		if (Object1.flixelType == TILEMAP)
		{
			var tilemap:FlxBaseTilemap<Dynamic> = cast Object1;
			return tilemap.overlapsWithCallback(Object2, separateY);
		}
		if (Object2.flixelType == TILEMAP)
		{
			var tilemap:FlxBaseTilemap<Dynamic> = cast Object2;
			return tilemap.overlapsWithCallback(Object1, separateY, true);
		}

		var overlap:Float = computeOverlapY(Object1, Object2);
		// Then adjust their positions and velocities accordingly (if there was any overlap)
		if (overlap != 0)
		{
			var obj1delta:Float = Object1.y - Object1.last.y;
			var obj2delta:Float = Object2.y - Object2.last.y;
			var obj1v:Float = Object1.velocity.y;
			var obj2v:Float = Object2.velocity.y;

			if (!obj1immovable && !obj2immovable)
			{
				overlap *= 0.5;
				Object1.y = Object1.y - overlap;
				Object2.y += overlap;

				var obj1velocity:Float = Math.sqrt((obj2v * obj2v * Object2.mass) / Object1.mass) * ((obj2v > 0) ? 1 : -1);
				var obj2velocity:Float = Math.sqrt((obj1v * obj1v * Object1.mass) / Object2.mass) * ((obj1v > 0) ? 1 : -1);
				var average:Float = (obj1velocity + obj2velocity) * 0.5;
				obj1velocity -= average;
				obj2velocity -= average;
				Object1.velocity.y = average + obj1velocity * Object1.elasticity;
				Object2.velocity.y = average + obj2velocity * Object2.elasticity;
			}
			else if (!obj1immovable)
			{
				Object1.y = Object1.y - overlap;
				Object1.velocity.y = obj2v - obj1v * Object1.elasticity;
				// This is special case code that handles cases like horizontal moving platforms you can ride
				if (Object1.collisonXDrag && Object2.active && Object2.moves && (obj1delta > obj2delta))
				{
					Object1.x += Object2.x - Object2.last.x;
				}
			}
			else if (!obj2immovable)
			{
				Object2.y += overlap;
				Object2.velocity.y = obj1v - obj2v * Object2.elasticity;
				// This is special case code that handles cases like horizontal moving platforms you can ride
				if (Object2.collisonXDrag && Object1.active && Object1.moves && (obj1delta < obj2delta))
				{
					Object2.x += Object1.x - Object1.last.x;
				}
			}
			return true;
		}

		return false;
	}

	/**
	 * Checking overlap and updating touching variables, Y-axis part used by `updateTouchingFlags`.
	 *
	 * @param   Object1   Any `FlxObjectOld`.
	 * @param   Object2   Any other `FlxObjectOld`.
	 * @return  Whether the objects in fact touched along the Y axis.
	 */
	public static function updateTouchingFlagsY(Object1:FlxObjectOld, Object2:FlxObjectOld):Bool
	{
		// If one of the objects is a tilemap, just pass it off.
		if (Object1.flixelType == TILEMAP)
		{
			var tilemap:FlxBaseTilemap<Dynamic> = cast Object1;
			return tilemap.overlapsWithCallback(Object2, updateTouchingFlagsY);
		}
		if (Object2.flixelType == TILEMAP)
		{
			var tilemap:FlxBaseTilemap<Dynamic> = cast Object2;
			return tilemap.overlapsWithCallback(Object1, updateTouchingFlagsY, true);
		}
		// Since we are not separating, always return any amount of overlap => false as last parameter
		return computeOverlapY(Object1, Object2, false) != 0;
	}

	/**
	 * X position of the upper left corner of this object in world space.
	 */
	public var x(default, set):Float = 0;

	/**
	 * Y position of the upper left corner of this object in world space.
	 */
	public var y(default, set):Float = 0;

	/**
	 * The width of this object's hitbox. For sprites, use `offset` to control the hitbox position.
	 */
	@:isVar
	public var width(get, set):Float;

	/**
	 * The height of this object's hitbox. For sprites, use `offset` to control the hitbox position.
	 */
	@:isVar
	public var height(get, set):Float;

	/**
	 * Whether or not the coordinates should be rounded during rendering.
	 * Does not affect `copyPixels()`, which can only render on whole pixels.
	 * Defaults to the camera's global `pixelPerfectRender` value,
	 * but overrides that value if not equal to `null`.
	 */
	public var pixelPerfectRender(default, set):Null<Bool>;

	/**
	 * Whether or not the position of this object should be rounded before any `draw()` or collision checking.
	 */
	public var pixelPerfectPosition:Bool = true;

	/**
	 * Set the angle (in degrees) of a sprite to rotate it. WARNING: rotating sprites
	 * decreases their rendering performance by a factor of ~10x when using blitting!
	 */
	public var angle(default, set):Float = 0;

	/**
	 * Set this to `false` if you want to skip the automatic motion/movement stuff (see `updateMotion()`).
	 * `FlxObjectOld` and `FlxSprite` default to `true`. `FlxText`, `FlxTileblock` and `FlxTilemap` default to `false`.
	 */
	public var moves(default, set):Bool = true;

	/**
	 * Whether an object will move/alter position after a collision.
	 */
	public var immovable(default, set):Bool = false;

	/**
	 * Whether the object collides or not. For more control over what directions the object will collide from,
	 * use collision constants (like `LEFT`, `FLOOR`, etc) to set the value of `allowCollisions` directly.
	 */
	public var solid(get, set):Bool;

	/**
	 * Controls how much this object is affected by camera scrolling. `0` = no movement (e.g. a background layer),
	 * `1` = same movement speed as the foreground. Default value is `(1,1)`,
	 * except for UI elements like `FlxButton` where it's `(0,0)`.
	 */
	public var scrollFactor(default, null):FlxPoint;

	/**
	 * The basic speed of this object (in pixels per second).
	 */
	public var velocity(default, null):FlxPoint;

	/**
	 * How fast the speed of this object is changing (in pixels per second).
	 * Useful for smooth movement and gravity.
	 */
	public var acceleration(default, null):FlxPoint;

	/**
	 * This isn't drag exactly, more like deceleration that is only applied
	 * when `acceleration` is not affecting the sprite.
	 */
	public var drag(default, null):FlxPoint;

	/**
	 * If you are using `acceleration`, you can use `maxVelocity` with it
	 * to cap the speed automatically (very useful!).
	 */
	public var maxVelocity(default, null):FlxPoint;

	/**
	 * Important variable for collision processing.
	 * By default this value is set automatically during at the start of `update()`.
	 */
	public var last(default, null):FlxPoint;

	/**
	 * The virtual mass of the object. Default value is 1. Currently only used with elasticity
	 * during collision resolution. Change at your own risk; effects seem crazy unpredictable so far!
	 */
	public var mass:Float = 1;

	/**
	 * The bounciness of this object. Only affects collisions. Default value is 0, or "not bouncy at all."
	 */
	public var elasticity:Float = 0;

	/**
	 * This is how fast you want this sprite to spin (in degrees per second).
	 */
	public var angularVelocity:Float = 0;

	/**
	 * How fast the spin speed should change (in degrees per second).
	 */
	public var angularAcceleration:Float = 0;

	/**
	 * Like drag but for spinning.
	 */
	public var angularDrag:Float = 0;

	/**
	 * Use in conjunction with angularAcceleration for fluid spin speed control.
	 */
	public var maxAngular:Float = 10000;

	/**
	 * Handy for storing health percentage or armor points or whatever.
	 */
	public var health:Float = 1;

	/**
	 * Bit field of flags (use with UP, DOWN, LEFT, RIG