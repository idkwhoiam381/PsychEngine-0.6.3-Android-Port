package mobile.options;

#if desktop
import Discord.DiscordClient;
#end
import openfl.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.FlxSubState;
import openfl.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;
import options.BaseOptionsMenu;
import options.Option;
import openfl.Lib;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import mobile.options.MobileOptionsSubState;
import mobile.backend.StorageUtil;

using StringTools;

class MobileOptionsSubState extends BaseOptionsMenu
{
    #if android
	var storageTypes:Array<String> = ["EXTERNAL_DATA", "EXTERNAL_OBB", "EXTERNAL_MEDIA", "EXTERNAL"];
	var externalPaths:Array<String> = StorageUtil.checkExternalPaths(true);
	final lastStorageType:String = ClientPrefs.storageType;
	#end
	
	public function new()
	{
	    storageTypes = storageTypes.concat(externalPaths);
		title = 'Mobile Options';
		rpcTitle = 'Mobile Options Menu'; //hi, you can ask what is that, i will answer it's all what you needed lol.
		
		var option:Option = new Option('VirtualPad Alpha:', //mariomaster was here again
			'Changes VirtualPad Alpha -cool feature',
			'VirtualPadAlpha',
			'float',
			#if mobile 0.75 #else 0 #end);
		option.scrollSpeed = 1.6;
		option.minValue = 0;
		option.maxValue = 1;
		option.changeValue = 0.01;
		option.decimals = 2;
		addOption(option);
        option.onChange = onChangePadAlpha;
		super();
		
	var option:Option = new Option('Extra Controls',
		"Allow Extra Controls",
		'extraKeys',
		'float',
		2);
	option.scrollSpeed = 1.6;
	option.minValue = 0;
	option.maxValue = 4;
	option.changeValue = 1;
	option.decimals = 1;
	addOption(option);
		
	var option:Option = new Option('Extra Control Location:',
		"Choose Extra Control Location",
		'hitboxLocation',
		'string',
		'Bottom',
		['Bottom', 'Top']);
	addOption(option);
		  
	var option:Option = new Option('Hitbox Mode:',
		"Choose your Hitbox Style!  -mariomaster",
		'hitboxmode',
		'string',
		'New',
		['Classic', 'New']);
	addOption(option);
		  
	var option:Option = new Option('Hitbox Design:',
		"Choose how your hitbox should look like.",
		'hitboxtype',
		'string',
		'Gradient',
		['Gradient', 'No Gradient' , 'No Gradient (Old)']);
	addOption(option);

	var option:Option = new Option('Hitbox Hint',
		'Hitbox Hint -I hate this',
		'hitboxhint',
		'bool',
		false);
	addOption(option);
		
	var option:Option = new Option('Hitbox Opacity', //mariomaster was here again
		'Changes hitbox opacity -omg',
		'hitboxalpha',
		'float',
		0.7);
	option.scrollSpeed = 1.6;
	option.minValue = 0.0;
	option.maxValue = 1;
	option.changeValue = 0.1;
	option.decimals = 1;
	addOption(option);
	
	#if mobile
	var option:Option = new Option('Wide Screen Mode',
		'If checked, The game will stetch to fill your whole screen. (WARNING: Can result in bad visuals & break some mods that resizes the game/cameras)',
		'wideScreen',
		'bool');
	option.onChange = () -> FlxG.scaleMode = new MobileScaleMode();
	addOption(option);
	#end
		
	#if android
	var option:Option = new Option('Storage Type',
		'Which folder Psych Engine should use?',
		'storageType',
		'string',
		null,
		storageTypes);
		addOption(option);
	#end

		super();
	}

	#if android
	function onStorageChange():Void
	{
		File.saveContent(lime.system.System.applicationStorageDirectory + 'storagetype.txt', ClientPrefs.storageType);
	
		var lastStoragePath:String = StorageType.fromStrForce(lastStorageType) + '/';
		
		if (lastStorageType == 'EXTERNAL_DATA' || lastStorageType == 'EXTERNAL_OBB' || lastStorageType == 'EXTERNAL_MEDIA')
		{
    		try
    		{
    		    if (lastStorageType == 'EXTERNAL_DATA' || lastStorageType == 'EXTERNAL_OBB' || lastStorageType == 'EXTERNAL_MEDIA') //Double Check
    			    Sys.command('rm', ['-rf', lastStoragePath]);
    		}
    		catch (e:haxe.Exception)
    			trace('Failed to remove last directory. (${e.message})');
		}
	}
	#end

	override public function destroy() {
		super.destroy();
		#if android
		if (ClientPrefs.storageType != lastStorageType) {
			onStorageChange();
			ClientPrefs.saveSettings();
			CoolUtil.showPopUp('Storage Type has been changed and you needed restart the game!!\nPress OK to close the game.', 'Notice!');
			lime.system.System.exit(0);
		}
		#end
	}
	
	function onChangePadAlpha()
	{
    	ClientPrefs.saveSettings();
    	_virtualpad.alpha = ClientPrefs.VirtualPadAlpha;
	}
}
