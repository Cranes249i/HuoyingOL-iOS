package airgame.bridge
{
   import flash.display.*;
   import flash.events.*;
   import flash.system.*;
   import flash.text.*;
   import flash.utils.*;
   
   public class GameBridge
   {
      
      private static var objects:Object = {};
      
      private static var ids:Dictionary = new Dictionary(true);
      
      private static var nextID:uint = 1;
      
      public static var playerHideAttempts:uint = 0;
      
      public static var playerHideFound:uint = 0;
      
      public function GameBridge()
      {
         super();
      }
      
      public static function hideOtherPlayers(param1:Stage) : Boolean
      {
         var _loc6_:DisplayObject = null;
         var _loc7_:DisplayObjectContainer = null;
         var _loc8_:MovieClip = null;
         var _loc9_:int = 0;
         ++playerHideAttempts;
         var _loc2_:DisplayObjectContainer = param1.getChildByName("mainUI") as DisplayObjectContainer;
         if(!_loc2_)
         {
            return false;
         }
         var _loc3_:Array = [_loc2_];
         var _loc4_:uint = 5000;
         var _loc5_:uint = 0;
         while(_loc5_ < _loc3_.length && Boolean(_loc4_--))
         {
            _loc6_ = _loc3_[_loc5_++] as DisplayObject;
            if(!(!_loc6_.visible || _loc6_.alpha == 0))
            {
               if(_loc6_.name == "otherPlayerVisibleBtn" && _loc6_ is MovieClip)
               {
                  ++playerHideFound;
                  _loc8_ = MovieClip(_loc6_);
                  if(_loc8_.currentFrame == 2)
                  {
                     return true;
                  }
                  if(_loc8_.currentFrame != 1)
                  {
                     return false;
                  }
                  if(_loc8_.numChildren == 0)
                  {
                     return false;
                  }
                  _loc6_ = _loc8_.getChildAt(0);
                  _loc6_.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN,true,false,0,0,null,false,false,false,true));
                  _loc6_.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_UP,true));
                  _loc6_.dispatchEvent(new MouseEvent(MouseEvent.CLICK,true));
                  _loc6_.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OUT,true));
                  _loc6_.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OUT,false));
                  return _loc8_.currentFrame == 2;
               }
               _loc7_ = _loc6_ as DisplayObjectContainer;
               if(Boolean(_loc7_))
               {
                  _loc9_ = 0;
                  while(_loc9_ < _loc7_.numChildren)
                  {
                     _loc3_.push(_loc7_.getChildAt(_loc9_));
                     _loc9_++;
                  }
               }
            }
         }
         return false;
      }
      
      private static function walk(param1:DisplayObject, param2:String, param3:Array, param4:uint = 0) : void
      {
         var _loc8_:Object = null;
         var _loc9_:Object = null;
         var _loc10_:uint = 0;
         var _loc11_:DisplayObject = null;
         if(param4 > 30 || param3.length >= 1500 || !param1.visible || param1.alpha == 0 || Boolean(/chat|talk/i.test(param2)))
         {
            return;
         }
         var _loc5_:String = ids[param1];
         if(!_loc5_)
         {
            _loc5_ = "n" + nextID++;
            ids[param1] = _loc5_;
         }
         objects[_loc5_] = param1;
         var _loc6_:String = param1 is TextField ? TextField(param1).text : (param1 is StaticText ? StaticText(param1).text : null);
         if(_loc6_ && _loc6_.replace(/\s/g,"").length || /close|btn|button|restPK|autoFight|defaultOk|getOut|confirm|sure|^ok$/i.test(param1.name) || param1.name == "arena" || param1 is SimpleButton || param1 is Sprite && Sprite(param1).buttonMode || Boolean(/naruto\.component\.controls::Button/.test(getQualifiedClassName(param1))))
         {
            _loc8_ = {
               "id":_loc5_,
               "name":param1.name,
               "path":param2,
               "type":getQualifiedClassName(param1)
            };
            if(Boolean(_loc6_))
            {
               _loc8_.text = _loc6_.substr(0,180);
            }
            if(param1 is MovieClip)
            {
               _loc8_.frame = MovieClip(param1).currentFrame;
            }
            if(param1 is InteractiveObject)
            {
               _loc8_.mouseEnabled = InteractiveObject(param1).mouseEnabled;
            }
            if("enabled" in param1)
            {
               _loc8_.enabled = Object(param1).enabled;
            }
            _loc9_ = param1.getBounds(param1.stage);
            _loc8_.bounds = [_loc9_.x,_loc9_.y,_loc9_.width,_loc9_.height];
            param3.push(_loc8_);
         }
         var _loc7_:DisplayObjectContainer = param1 as DisplayObjectContainer;
         if(Boolean(_loc7_))
         {
            _loc10_ = 0;
            while(_loc10_ < _loc7_.numChildren)
            {
               _loc11_ = _loc7_.getChildAt(_loc10_);
               walk(_loc11_,param2 + "." + _loc11_.name,param3,param4 + 1);
               _loc10_++;
            }
         }
      }
      
      public static function execute(param1:Stage, param2:Object) : Object
      {
         var _loc3_:Object = null;
         var _loc4_:Object = null;
         var _loc5_:Array = null;
         var _loc6_:Object = null;
         var _loc7_:Object = null;
         var _loc8_:Object = null;
         var _loc9_:Object = null;
         var _loc10_:Object = null;
         var _loc11_:DisplayObject = null;
         if(param2.op == "ping")
         {
            return {"alive":true};
         }
         if(param2.op == "state" || param2.op == "status")
         {
            _loc3_ = null;
            _loc4_ = null;
            try
            {
               _loc8_ = Object(RuntimeAdapter.gameDomain.getDefinition("base.ApplicationData")).singleton;
               _loc9_ = _loc8_.selfInfo;
               _loc3_ = {
                  "account":String(_loc8_.selfuin),
                  "zone":String(_loc8_.selfSrv),
                  "name":(Boolean(_loc9_) ? _loc9_.name : null),
                  "level":(Boolean(_loc9_) ? _loc9_.level : null),
                  "dianquan":(Boolean(_loc9_) ? _loc9_.dianquan : null),
                  "yuanbao":(Boolean(_loc9_) ? _loc9_.yuanbao : null),
                  "isFightLock":_loc8_.isFightLock
               };
               _loc10_ = _loc8_.getModel("battleStart");
               if(Boolean(_loc10_))
               {
                  _loc4_ = {
                     "isFighting":_loc10_.isFighting,
                     "type":_loc10_.type,
                     "replayBytes":(Boolean(_loc10_.replayData) ? _loc10_.replayData.length : 0)
                  };
               }
            }
            catch(error:Error)
            {
            }
            _loc5_ = [];
            if(param2.op == "state")
            {
               objects = {};
               walk(param1,"stage",_loc5_);
            }
            _loc6_ = getDefinitionByName("MobileGame");
            _loc7_ = Object(getDefinitionByName("flash.desktop.NativeApplication")).nativeApplication;
            return {
               "network":Socket.diagnostics,
               "identity":_loc3_,
               "battle":_loc4_,
               "nodes":_loc5_,
               "externalCalls":Object(getDefinitionByName("airgame.bridge.ExternalInterface")).calls,
               "runtime":{
                  "playerHideAttempts":playerHideAttempts,
                  "playerHideFound":playerHideFound,
                  "playersHidden":_loc6_.playersHidden,
                  "hostAttached":Boolean(_loc6_.instance && _loc6_.instance.parent === param1),
                  "gameDomainIsolated":Boolean(RuntimeAdapter.gameDomain && RuntimeAdapter.gameDomain !== ApplicationDomain.currentDomain),
                  "speed":SpeedClock.multiplier,
                  "virtualTime":SpeedClock.now(),
                  "ticks":_loc6_.appTicks,
                  "active":_loc6_.appActive,
                  "executeInBackground":_loc7_.executeInBackground,
                  "backgroundServiceRunning":_loc6_.backgroundServiceRunning
               },
               "bundledAssetReads":Object(getDefinitionByName("airgame.bridge.URLLoader")).bundledAssetReads,
               "bundledBootstrapReads":Object(getDefinitionByName("airgame.bridge.URLLoader")).bundledBootstrapReads,
               "files":Object(getDefinitionByName("airgame.bridge.URLLoader")).diagnostics,
               "loaders":Object(getDefinitionByName("airgame.bridge.Loader")).diagnostics,
               "stage":{
                  "width":param1.stageWidth,
                  "height":param1.stageHeight,
                  "frameRate":param1.frameRate,
                  "scaleMode":param1.scaleMode,
                  "displayState":param1.displayState
               }
            };
         }
         if(param2.op == "click")
         {
            _loc11_ = objects[param2.id];
            if(!_loc11_ || _loc11_.stage !== param1 || !_loc11_.visible || _loc11_.name !== param2.name || getQualifiedClassName(_loc11_) !== param2.type)
            {
               throw new Error("stale_or_wrong_control");
            }
            if("enabled" in _loc11_ && !Object(_loc11_).enabled)
            {
               throw new Error("disabled_control");
            }
            _loc11_.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER,true));
            _loc11_.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN,true,false,0,0,null,false,false,false,true));
            _loc11_.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_UP,true));
            _loc11_.dispatchEvent(new MouseEvent(MouseEvent.CLICK,true));
            _loc11_.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OUT,true));
            return {
               "dispatched":true,
               "name":_loc11_.name,
               "type":getQualifiedClassName(_loc11_)
            };
         }
         throw new Error("unsupported_bridge_operation");
      }
   }
}

