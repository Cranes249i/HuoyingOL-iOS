package airgame.bridge
{
   import flash.utils.*;
   
   public class EntryCompatibility
   {
      
      private static var b:ByteArray;
      
      private static var strings:Array;
      
      private static var names:Array;
      
      private static var kinds:Array;
      
      private static var targets:Object;
      
      private static var fields:Object;
      
      public function EntryCompatibility()
      {
         super();
      }
      
      private static function need(param1:Boolean) : void
      {
         if(!param1)
         {
            throw new Error("entry_layout_changed");
         }
      }
      
      private static function u() : uint
      {
         var _loc3_:uint = 0;
         var _loc1_:uint = 0;
         var _loc2_:uint = 0;
         while(_loc2_ < 5)
         {
            need(b.bytesAvailable > 0);
            _loc3_ = uint(b.readUnsignedByte());
            _loc1_ |= (_loc3_ & 0x7F) << 7 * _loc2_;
            if(!(_loc3_ & 0x80))
            {
               return _loc1_;
            }
            _loc2_++;
         }
         throw new Error("entry_integer_invalid");
      }
      
      private static function put(param1:ByteArray, param2:uint) : void
      {
         while(param2 >= 128)
         {
            param1.writeByte(param2 & 0x7F | 0x80);
            param2 >>>= 7;
         }
         param1.writeByte(param2);
      }
      
      private static function copy(param1:ByteArray, param2:uint, param3:uint) : void
      {
         need(param3 >= param2 && param3 <= b.length);
         if(param3 > param2)
         {
            param1.writeBytes(b,param2,param3 - param2);
         }
      }
      
      private static function trait(param1:String) : void
      {
         var _loc5_:uint = 0;
         var _loc6_:uint = 0;
         var _loc2_:uint = uint(u());
         var _loc3_:uint = uint(b.readUnsignedByte());
         var _loc4_:uint = uint(_loc3_ & 0x0F);
         if(_loc4_ == 0 || _loc4_ == 6)
         {
            u();
            u();
            if(Boolean(u()))
            {
               b.readUnsignedByte();
            }
            if(param1 == "KeyFileLoader")
            {
               fields[names[_loc2_]] = _loc2_;
            }
         }
         else if(_loc4_ == 1 || _loc4_ == 2 || _loc4_ == 3)
         {
            u();
            _loc5_ = uint(u());
            if(param1 == "entry" && names[_loc2_] == "addBuildVersion" || param1 == "KeyFileLoader" && (names[_loc2_] == "loadNextRSL" || names[_loc2_] == "getConfig"))
            {
               targets[param1 + "." + names[_loc2_]] = _loc5_;
            }
         }
         else if(_loc4_ == 4 || _loc4_ == 5)
         {
            u();
            u();
         }
         else
         {
            need(false);
         }
         if(Boolean(_loc3_ & 0x40))
         {
            _loc6_ = uint(u());
            while(Boolean(_loc6_--))
            {
               u();
            }
         }
      }
      
      private static function traits(param1:String) : void
      {
         var _loc2_:uint = uint(u());
         while(Boolean(_loc2_--))
         {
            trait(param1);
         }
      }
      
      public static function apply(param1:ByteArray) : ByteArray
      {
         var _loc2_:uint = 0;
         var _loc3_:uint = 0;
         var _loc4_:uint = 0;
         var _loc5_:uint = 0;
         var _loc6_:uint = 0;
         var _loc7_:uint = 0;
         var _loc8_:uint = 0;
         var _loc13_:Object = null;
         var _loc21_:String = null;
         var _loc22_:uint = 0;
         var _loc23_:String = null;
         var _loc24_:uint = 0;
         var _loc25_:uint = 0;
         var _loc26_:uint = 0;
         var _loc27_:uint = 0;
         var _loc28_:uint = 0;
         var _loc29_:uint = 0;
         var _loc30_:uint = 0;
         var _loc31_:uint = 0;
         var _loc32_:uint = 0;
         var _loc33_:ByteArray = null;
         b = param1;
         b.position = 4;
         strings = [""];
         names = [""];
         kinds = [0];
         targets = {};
         fields = {};
         _loc3_ = 0;
         while(_loc3_ < 2)
         {
            _loc4_ = uint(u());
            _loc2_ = 1;
            while(_loc2_ < _loc4_)
            {
               u();
               _loc2_++;
            }
            _loc3_++;
         }
         _loc4_ = uint(u());
         b.position += Math.max(0,int(_loc4_) - 1) * 8;
         _loc4_ = uint(u());
         _loc2_ = 1;
         while(_loc2_ < _loc4_)
         {
            _loc5_ = uint(u());
            need(_loc5_ <= b.bytesAvailable);
            strings.push(b.readUTFBytes(_loc5_));
            _loc2_++;
         }
         _loc4_ = uint(u());
         _loc2_ = 1;
         while(_loc2_ < _loc4_)
         {
            b.readUnsignedByte();
            u();
            _loc2_++;
         }
         _loc4_ = uint(u());
         _loc2_ = 1;
         while(_loc2_ < _loc4_)
         {
            _loc5_ = uint(u());
            while(Boolean(_loc5_--))
            {
               u();
            }
            _loc2_++;
         }
         _loc4_ = uint(u());
         _loc2_ = 1;
         while(_loc2_ < _loc4_)
         {
            _loc5_ = uint(b.readUnsignedByte());
            kinds.push(_loc5_);
            _loc21_ = "";
            if(_loc5_ == 7 || _loc5_ == 13)
            {
               u();
               _loc21_ = strings[u()];
            }
            else if(_loc5_ == 15 || _loc5_ == 16)
            {
               _loc21_ = strings[u()];
            }
            else if(_loc5_ == 9 || _loc5_ == 14)
            {
               _loc21_ = strings[u()];
               u();
            }
            else if(_loc5_ == 27 || _loc5_ == 28)
            {
               u();
            }
            else if(_loc5_ == 29)
            {
               u();
               _loc7_ = uint(u());
               while(Boolean(_loc7_--))
               {
                  u();
               }
            }
            else
            {
               need(_loc5_ == 17 || _loc5_ == 18);
            }
            names.push(_loc21_);
            _loc2_++;
         }
         _loc4_ = uint(u());
         _loc2_ = 0;
         while(_loc2_ < _loc4_)
         {
            _loc7_ = uint(u());
            u();
            _loc3_ = 0;
            while(_loc3_ < _loc7_)
            {
               u();
               _loc3_++;
            }
            u();
            _loc22_ = uint(b.readUnsignedByte());
            if(Boolean(_loc22_ & 8))
            {
               _loc5_ = uint(u());
               while(Boolean(_loc5_--))
               {
                  u();
                  b.readUnsignedByte();
               }
            }
            if(Boolean(_loc22_ & 0x80))
            {
               _loc3_ = 0;
               while(_loc3_ < _loc7_)
               {
                  u();
                  _loc3_++;
               }
            }
            _loc2_++;
         }
         _loc4_ = uint(u());
         _loc2_ = 0;
         while(_loc2_ < _loc4_)
         {
            u();
            _loc7_ = uint(u());
            _loc3_ = 0;
            while(_loc3_ < _loc7_ * 2)
            {
               u();
               _loc3_++;
            }
            _loc2_++;
         }
         _loc8_ = uint(u());
         _loc2_ = 0;
         while(_loc2_ < _loc8_)
         {
            _loc23_ = names[u()];
            u();
            _loc22_ = uint(b.readUnsignedByte());
            if(Boolean(_loc22_ & 8))
            {
               u();
            }
            _loc7_ = uint(u());
            while(Boolean(_loc7_--))
            {
               u();
            }
            u();
            traits(_loc23_);
            _loc2_++;
         }
         _loc2_ = 0;
         while(_loc2_ < _loc8_)
         {
            u();
            traits("");
            _loc2_++;
         }
         _loc4_ = uint(u());
         _loc2_ = 0;
         while(_loc2_ < _loc4_)
         {
            u();
            traits("");
            _loc2_++;
         }
         _loc4_ = uint(u());
         var _loc9_:Array = [];
         _loc2_ = 0;
         while(_loc2_ < _loc4_)
         {
            _loc6_ = uint(b.position);
            _loc24_ = uint(u());
            _loc25_ = uint(b.position);
            u();
            _loc26_ = uint(b.position);
            u();
            u();
            u();
            _loc27_ = uint(b.position);
            _loc28_ = uint(u());
            _loc29_ = uint(b.position);
            need(_loc28_ <= b.bytesAvailable);
            b.position += _loc28_;
            _loc30_ = uint(b.position);
            _loc31_ = uint(u());
            _loc3_ = 0;
            while(_loc3_ < _loc31_ * 5)
            {
               u();
               _loc3_++;
            }
            traits("");
            _loc9_.push({
               "a":_loc6_,
               "z":b.position,
               "method":_loc24_,
               "stackAt":_loc25_,
               "stackEnd":_loc26_,
               "lengthAt":_loc27_,
               "codeAt":_loc29_,
               "end":_loc30_,
               "exceptions":_loc31_
            });
            _loc2_++;
         }
         need(b.position == b.length);
         var _loc10_:Object = null;
         var _loc11_:Object = null;
         var _loc12_:Object = null;
         for each(_loc13_ in _loc9_)
         {
            if(_loc13_.method === targets["entry.addBuildVersion"])
            {
               _loc10_ = _loc13_;
            }
            if(_loc13_.method === targets["KeyFileLoader.loadNextRSL"])
            {
               _loc11_ = _loc13_;
            }
            if(_loc13_.method === targets["KeyFileLoader.getConfig"])
            {
               _loc12_ = _loc13_;
            }
         }
         if(!_loc10_ && !_loc11_)
         {
            param1.position = 0;
            return param1;
         }
         need(_loc10_ != null && _loc11_ != null && _loc12_ != null && fields._cfg > 0 && fields._byteAssets > 0 && _loc10_.exceptions == 0 && _loc11_.exceptions == 0);
         b.position = _loc10_.codeAt;
         var _loc14_:uint = 0;
         while(b.position < Math.min(_loc10_.end,_loc10_.codeAt + 24))
         {
            _loc5_ = uint(b.readUnsignedByte());
            if(_loc5_ == 97 || _loc5_ == 104)
            {
               _loc32_ = uint(u());
               need(names[_loc32_] == "gameVersion");
               _loc14_ = uint(b.position);
               break;
            }
            if(_loc5_ == 96 || _loc5_ == 102 || _loc5_ == 44)
            {
               u();
            }
            else
            {
               need(_loc5_ == 208 || _loc5_ == 209 || _loc5_ == 48);
            }
         }
         need(_loc14_ > _loc10_.codeAt);
         var _loc15_:ByteArray = new ByteArray();
         copy(_loc15_,_loc10_.codeAt,_loc14_);
         _loc15_.writeByte(71);
         var _loc16_:uint = 0;
         _loc6_ = uint(_loc12_.codeAt);
         while(_loc6_ < _loc12_.end)
         {
            if(b[_loc6_] == 102)
            {
               b.position = _loc6_ + 1;
               _loc5_ = uint(u());
               if(kinds[_loc5_] == 27 || kinds[_loc5_] == 28)
               {
                  _loc16_ = _loc5_;
                  break;
               }
            }
            _loc6_++;
         }
         var _loc17_:int = int(strings.indexOf("pluginCfg"));
         need(_loc16_ > 0 && _loc17_ > 0 && b[_loc11_.codeAt] == 208 && b[_loc11_.codeAt + 1] == 48);
         var _loc18_:ByteArray = new ByteArray();
         copy(_loc18_,_loc11_.codeAt,_loc11_.codeAt + 2);
         _loc18_.writeByte(208);
         _loc18_.writeByte(102);
         put(_loc18_,fields._byteAssets);
         _loc18_.writeByte(208);
         _loc18_.writeByte(102);
         put(_loc18_,fields._cfg);
         _loc18_.writeByte(44);
         put(_loc18_,_loc17_);
         _loc18_.writeByte(102);
         put(_loc18_,_loc16_);
         _loc18_.writeByte(102);
         put(_loc18_,_loc16_);
         _loc18_.writeByte(17);
         _loc18_.writeByte(1);
         _loc18_.writeByte(0);
         _loc18_.writeByte(0);
         _loc18_.writeByte(71);
         copy(_loc18_,_loc11_.codeAt + 2,_loc11_.end);
         var _loc19_:ByteArray = new ByteArray();
         var _loc20_:uint = 0;
         for each(_loc13_ in _loc9_)
         {
            _loc33_ = _loc13_ === _loc10_ ? _loc15_ : (_loc13_ === _loc11_ ? _loc18_ : null);
            if(_loc33_)
            {
               copy(_loc19_,_loc20_,_loc13_.stackAt);
               b.position = _loc13_.stackAt;
               put(_loc19_,Math.max(3,u()));
               copy(_loc19_,_loc13_.stackEnd,_loc13_.lengthAt);
               put(_loc19_,_loc33_.length);
               _loc19_.writeBytes(_loc33_);
               _loc20_ = uint(_loc13_.end);
            }
         }
         copy(_loc19_,_loc20_,b.length);
         _loc19_.position = 0;
         return _loc19_;
      }
   }
}

