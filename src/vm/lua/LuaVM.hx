package vm.lua;

import llua.Convert;
import llua.Lua;
import llua.State;
import llua.LuaL;
import haxe.Exception;
import lime.app.Application;
import openfl.Lib;
import sys.FileSystem;
import sys.io.File;
using StringTools;

import haxe.DynamicAccess;


class LuaException extends Exception {}

class LuaVM {
	public var version(default, never):String = Lua.version();

	public var errorHandler:String->Void;

	public var state:State;
	static var funcs = [];


	public function new() {
		state = LuaL.newstate();
		LuaL.openlibs(state);

		Lua.init_callbacks(state);
	}

	#if tink_core
	public function tryRun(s, ?g)
		return tink.core.Error.catchExceptions(run.bind(s, g));

	public function tryCall(n, a)
		return tink.core.Error.catchExceptions(call.bind(n, a));
	#end

	public function run(script:String, ?globals:DynamicAccess<Any>):Any {
		if(globals != null) for(key in globals.keys()) setGlobalVar(key, globals.get(key));
		if(LuaL.dostring(state,script)!=0){
                        if (!FileSystem.exists(Generic.returnPath() + 'logs'))
				FileSystem.createDirectory(Generic.returnPath() + 'logs');

			File.saveContent(Generic.returnPath()
				+ 'logs/'
				+ Lib.application.meta.get('file')
				+ '-'
				+ Date.now().toString().replace(' ', '-').replace(':', "'")
				+ '.log',
				getErrorMessage(state)
				+ '\n');

                        Lib.application.window.alert(getErrorMessage(state), 'LuaVM Error');
			throw new LuaException(getErrorMessage(state));
		}else
                        Lib.application.window.alert('it seems fine?', 'LuaVM');
			return getReturnValues(state);
	}

	public function runFile(script:String, ?globals:DynamicAccess<Any>):Any {
		if(globals != null) for(key in globals.keys()) setGlobalVar(key, globals.get(key));
		if(LuaL.dofile(state,script)!=0){
                        if (!FileSystem.exists(Generic.returnPath() + 'logs'))
				FileSystem.createDirectory(Generic.returnPath() + 'logs');

			File.saveContent(Generic.returnPath()
				+ 'logs/'
				+ Lib.application.meta.get('file')
				+ '-'
				+ Date.now().toString().replace(' ', '-').replace(':', "'")
				+ '.log',
				getErrorMessage(state)
				+ '\n');

                        Lib.application.window.alert(getErrorMessage(state), 'LuaVM Error');
			throw new LuaException(getErrorMessage(state));
		}else
                        Lib.application.window.alert('it seems fine?', 'LuaVM');
			return getReturnValues(state);
	}

	public function call(name:String, args:Array<Any>, ?type: String):Any {
		var retValue:Any = null;
		var result : Any = null;
		try{
			Lua.getglobal(state, name);
			if(Lua.isfunction(state,-1)==true){
				for(arg in args) Convert.toLua(state, arg);
				result = Lua.pcall(state, args.length, 1, 0);
				if(result!=0){
					var err = getErrorMessage(state);
                                        if (!FileSystem.exists(Generic.returnPath() + 'logs')) {
					        FileSystem.createDirectory(Generic.returnPath() + 'logs');
                                        }
				        File.saveContent(Generic.returnPath()
					        + 'logs/'
					        + Lib.application.meta.get('file')
					        + '-'
					        + Date.now().toString().replace(' ', '-').replace(':', "'")
					        + '.log',
					        err
					        + '\n');

                                        Lib.application.window.alert(err, 'Lua VM Call Error');
					if(errorHandler!=null){
						errorHandler(err);
					}
					//LuaL.error(state,err);
				}else{
					retValue = convert(Convert.fromLua(state,-1),type);
				}
			}
		}catch(e:Any){
			trace(e);
		}
		return retValue;
	}

	public function callF(name:String, func:Void->Int, ?type: String):Any {
		var retValue:Any = null;
		var result : Any = null;
		try{
			Lua.getglobal(state, name);
			if(Lua.isfunction(state,-1)==true){
				var argC:Int = func();
				result = Lua.pcall(state, argC, 1, 0);
				if(result!=0){
					var err = getErrorMessage(state);
                                        if (!FileSystem.exists(Generic.returnPath() + 'logs')) {
					        FileSystem.createDirectory(Generic.returnPath() + 'logs');
                                        }
				        File.saveContent(Generic.returnPath()
					        + 'logs/'
					        + Lib.application.meta.get('file')
					        + '-'
					        + Date.now().toString().replace(' ', '-').replace(':', "'")
					        + '.log',
					        err
					        + '\n');

                                        Lib.application.window.alert(err, 'Lua VM Call Error');
					if(errorHandler!=null){
						errorHandler(err);
					}
					//LuaL.error(state,err);
				}else{
					retValue = convert(Convert.fromLua(state,-1),type);
				}
			}
		}catch(e:Any){
			trace(e);
		}
		return retValue;
	}

	// https://notabug.org/endes/haxe-lua-plugins/src/master/src/beartek/lua_plugins/Luaplugin.hx
	// Credit to endes
	private function convert(v : Any, type : String) : Dynamic {
    if( Std.is(v, String) && type != null ) {
      var v : String = v;
      if( type.substr(0, 4) == 'array' ) {
        if( type.substr(4) == 'float' ) {
          var array : Array<String> = v.split(',');
          var array2 : Array<Float> = new Array();

          for( vars in array ) {
            array2.push(Std.parseFloat(vars));
          }

          return array2;
        } else if( type.substr(4) == 'int' ) {
          var array : Array<String> = v.split(',');
          var array2 : Array<Int> = new Array();

          for( vars in array ) {
            array2.push(Std.parseInt(vars));
          }

          return array2;
        } else {
          var array : Array<String> = v.split(',');
          return array;
        }
      } else if( type == 'float' ) {
        return Std.parseFloat(v);
      } else if( type == 'int' ) {
        return Std.parseInt(v);
      } else if( type == 'bool' ) {
        if( v == 'true' ) {
          return true;
        } else {
          return false;
        }
      } else {
        return v;
      }
    } else {
      return v;
    }
  }


	public function setGlobalVar(name:String, value:Any) {
		//Convert.toLua(state, value);
		//Lua.setglobal(state, name);
		try{
			switch Type.typeof(value){
				case TFunction:
					Lua_helper.add_callback(state,name,value);
				default:
					Convert.toLua(state, value);
					Lua.setglobal(state, name);
			}
		}catch(e:Any){
			trace(e);
		}
	}

	public function getGlobalVar(name:String, ?type:String):Dynamic{
		var result:Any = null;
		Lua.getglobal(state,name);
		result = Convert.fromLua(state,-1);
		Lua.pop(state,1);
		if(result!=null){
			return convert(result,type);
		}else{
			return null;
		}
	}

	public function unsetGlobalVar(name:String) {
		Lua.pushnil(state);
		Lua.setglobal(state, name);
	}

	public function destroy() {
		if(state !=null){
			trace("closed lua");
			Lua.close(state);
			state = null;
		}
	}


	static function getReturnValues(state) {
		var lua_v:Int;
		var v:Any = null;
		while((lua_v = Lua.gettop(state)) != 0) {
			v = Convert.fromLua(state, lua_v);
			Lua.pop(state, 1);
		}
		// returns the first value (in case of multi return) returned from the Lua function
		return v;
	}

	static function getErrorMessage(state) {
		var v:String = Lua.tostring(state, -1);
		Lua.pop(state, 1);
		return v;
	}

}


/**
 *
 *  Stack is pushed downwards, i.e.:
 *    Push: add element to the top
 *    Pop: remove element from the top
 *
 *  Visualization of the Stack:
 *
 *  -- Top of stack, last pushed / newest element, index -1, index n
 *  --
 *  --
 *  --
 *  --
 *  -- Bottom of stack, first pushed / oldest element, index 1, index -n
 *
 */
