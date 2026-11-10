package airgame.bridge
{
   import flash.system.ApplicationDomain;
   import flash.utils.*;
   
   public class RuntimeAdapter
   {
      
      public static var gameDomain:ApplicationDomain;
      
      public static var edits:uint = 0;
      
      public static var emptyImportsRemoved:uint = 0;
      
      public static var redirectNet:Boolean = false;
      
      public static var redirectTime:Boolean = false;
      
      public function RuntimeAdapter()
      {
         super();
      }
      
      private static function need(param1:Boolean) : void
      {
         if(!param1)
         {
            throw new Error("invalid_public_swf");
         }
      }
      
      private static function number(param1:ByteArray) : uint
      {
         var _loc4_:uint = 0;
         var _loc2_:uint = 0;
         var _loc3_:uint = 0;
         while(_loc3_ < 5)
         {
            need(param1.bytesAvailable > 0);
            _loc4_ = param1.readUnsignedByte();
            _loc2_ |= (_loc4_ & 0x7F) << _loc3_ * 7;
            if(!(_loc4_ & 0x80))
            {
               return _loc2_;
            }
            _loc3_++;
         }
         throw new Error("invalid_abc_integer");
      }
      
      private static function integer(param1:ByteArray, param2:uint) : void
      {
         while(param2 >= 128)
         {
            param1.writeByte(param2 & 0x7F | 0x80);
            param2 >>>= 7;
         }
         param1.writeByte(param2);
      }
      
      private static function part(param1:ByteArray, param2:ByteArray, param3:uint, param4:uint) : void
      {
         need(param3 <= param4 && param4 <= param2.length);
         if(param4 > param3)
         {
            param1.writeBytes(param2,param3,param4 - param3);
         }
      }
      
      private static function emptyImport(param1:ByteArray, param2:uint, param3:uint, param4:uint) : Boolean
      {
         var _loc5_:uint = param4 == 71 ? 5 : 3;
         var _loc6_:String = "https://res.huoying.qq.com/empty.swf";
         var _loc7_:String = "http://res.huoying.qq.com/empty.swf";
         if(param3 != _loc6_.length + _loc5_ && param3 != _loc7_.length + _loc5_)
         {
            return false;
         }
         param1.position = param2;
         var _loc8_:String = param1.readUTFBytes(param3 - _loc5_);
         if(_loc8_ != _loc6_ && _loc8_ != _loc7_)
         {
            return false;
         }
         if(param1.readUnsignedByte() != 0)
         {
            return false;
         }
         if(param4 == 71 && (param1.readUnsignedByte() != 1 || param1.readUnsignedByte() != 0))
         {
            return false;
         }
         return param1.readUnsignedShort() == 0;
      }
      
      private static function abc(param1:ByteArray, param2:Boolean = false) : ByteArray
      {
         var _loc3_:uint = 0;
         var _loc4_:uint = 0;
         var _loc5_:uint = 0;
         var _loc6_:uint = 0;
         var _loc22_:uint = 0;
         var _loc23_:uint = 0;
         var _loc24_:Boolean = false;
         var _loc25_:uint = 0;
         var _loc26_:uint = 0;
         var _loc27_:String = null;
         var _loc28_:String = null;
         if(param2)
         {
            param1 = EntryCompatibility.apply(param1);
         }
         param1.position = 4;
         _loc4_ = 0;
         while(_loc4_ < 2)
         {
            _loc5_ = uint(number(param1));
            _loc3_ = 1;
            while(_loc3_ < _loc5_)
            {
               number(param1);
               _loc3_++;
            }
            _loc4_++;
         }
         _loc5_ = uint(number(param1));
         param1.position += Math.max(0,int(_loc5_) - 1) * 8;
         need(param1.position <= param1.length);
         var _loc7_:uint = param1.position;
         var _loc8_:uint = Math.max(1,number(param1));
         var _loc9_:uint = param1.position;
         var _loc10_:Array = [""];
         _loc3_ = 1;
         while(_loc3_ < _loc8_)
         {
            _loc5_ = uint(number(param1));
            need(_loc5_ <= param1.bytesAvailable);
            _loc10_.push(param1.readUTFBytes(_loc5_));
            _loc3_++;
         }
         var _loc11_:uint = param1.position;
         var _loc12_:uint = Math.max(1,number(param1));
         var _loc13_:uint = param1.position;
         var _loc14_:Array = [0];
         _loc3_ = 1;
         while(_loc3_ < _loc12_)
         {
            _loc6_ = param1.readUnsignedByte();
            _loc14_.push(number(param1));
            _loc3_++;
         }
         var _loc15_:uint = param1.position;
         _loc5_ = uint(number(param1));
         _loc3_ = 1;
         while(_loc3_ < _loc5_)
         {
            _loc22_ = uint(number(param1));
            _loc4_ = 0;
            while(_loc4_ < _loc22_)
            {
               number(param1);
               _loc4_++;
            }
            _loc3_++;
         }
         var _loc16_:uint = param1.position;
         var _loc17_:uint = uint(number(param1));
         var _loc18_:ByteArray = new ByteArray();
         var _loc19_:uint = 0;
         _loc3_ = 1;
         while(_loc3_ < _loc17_)
         {
            _loc23_ = param1.position;
            _loc6_ = param1.readUnsignedByte();
            _loc24_ = false;
            if(_loc6_ == 7 || _loc6_ == 13)
            {
               _loc25_ = uint(number(param1));
               _loc26_ = uint(number(param1));
               need(_loc25_ < _loc14_.length && _loc26_ < _loc10_.length && _loc14_[_loc25_] < _loc10_.length);
               _loc27_ = _loc10_[_loc14_[_loc25_]];
               _loc28_ = _loc10_[_loc26_];
               _loc24_ = _loc27_ == "flash.external" && _loc28_ == "ExternalInterface" || _loc27_ == "flash.system" && (_loc28_ == "LoaderContext" || _loc28_ == "Security") || _loc27_ == "flash.display" && _loc28_ == "Loader" || redirectNet && _loc27_ == "flash.net" && (_loc28_ == "URLLoader" || _loc28_ == "Socket") || redirectTime && _loc27_ == "flash.utils" && (_loc28_ == "Timer" || _loc28_ == "getTimer");
               if(_loc24_)
               {
                  _loc18_.writeByte(_loc6_);
                  integer(_loc18_,_loc12_);
                  integer(_loc18_,_loc26_);
                  _loc19_++;
               }
            }
            else if(_loc6_ == 15 || _loc6_ == 16 || _loc6_ == 27 || _loc6_ == 28)
            {
               number(param1);
            }
            else if(_loc6_ == 9 || _loc6_ == 14)
            {
               number(param1);
               number(param1);
            }
            else if(_loc6_ == 29)
            {
               number(param1);
               _loc22_ = uint(number(param1));
               _loc4_ = 0;
               while(_loc4_ < _loc22_)
               {
                  number(param1);
                  _loc4_++;
               }
            }
            else
            {
               need(_loc6_ == 17 || _loc6_ == 18);
            }
            if(!_loc24_)
            {
               part(_loc18_,param1,_loc23_,param1.position);
            }
            _loc3_++;
         }
         if(!_loc19_)
         {
            param1.position = 0;
            return param1;
         }
         var _loc20_:uint = param1.position;
         var _loc21_:ByteArray = new ByteArray();
         part(_loc21_,param1,0,_loc7_);
         integer(_loc21_,_loc8_ + 1);
         part(_loc21_,param1,_loc9_,_loc11_);
         integer(_loc21_,14);
         _loc21_.writeUTFBytes("airgame.bridge");
         integer(_loc21_,_loc12_ + 1);
         part(_loc21_,param1,_loc13_,_loc15_);
         _loc21_.writeByte(22);
         integer(_loc21_,_loc8_);
         part(_loc21_,param1,_loc15_,_loc16_);
         integer(_loc21_,_loc17_);
         _loc21_.writeBytes(_loc18_);
         part(_loc21_,param1,_loc20_,param1.length);
         edits += _loc19_;
         _loc21_.position = 0;
         return _loc21_;
      }
      
      public static function apply(param1:ByteArray, param2:Boolean = false) : ByteArray
      {
         var _loc12_:uint = 0;
         var _loc13_:uint = 0;
         var _loc14_:uint = 0;
         var _loc15_:uint = 0;
         var _loc16_:uint = 0;
         var _loc17_:uint = 0;
         var _loc18_:ByteArray = null;
         var _loc19_:uint = 0;
         var _loc20_:ByteArray = null;
         if(param1.length < 8)
         {
            return param1;
         }
         var _loc3_:ByteArray = new ByteArray();
         _loc3_.endian = Endian.LITTLE_ENDIAN;
         param1.position = 0;
         _loc3_.writeBytes(param1);
         _loc3_.position = 0;
         var _loc4_:String = _loc3_.readUTFBytes(3);
         if(_loc4_ != "FWS" && _loc4_ != "CWS" && _loc4_ != "ZWS")
         {
            return param1;
         }
         need(_loc3_.length >= 8);
         _loc3_.position = 4;
         var _loc5_:uint = _loc3_.readUnsignedInt();
         need(_loc5_ >= 12 && _loc5_ <= 134217728);
         var _loc6_:ByteArray = new ByteArray();
         if(_loc4_ == "CWS")
         {
            part(_loc6_,_loc3_,8,_loc3_.length);
            _loc6_.uncompress("zlib");
         }
         else if(_loc4_ == "ZWS")
         {
            need(_loc3_.length >= 17);
            part(_loc6_,_loc3_,12,17);
            _loc6_.endian = Endian.LITTLE_ENDIAN;
            _loc6_.writeUnsignedInt(_loc5_ - 8);
            _loc6_.writeUnsignedInt(0);
            part(_loc6_,_loc3_,17,_loc3_.length);
            _loc6_.uncompress("lzma");
         }
         else
         {
            part(_loc6_,_loc3_,8,_loc3_.length);
         }
         need(_loc6_.length == _loc5_ - 8);
         _loc3_.length = 8;
         _loc3_.position = 0;
         _loc3_.writeUTFBytes("FWS");
         _loc3_.position = 8;
         _loc3_.writeBytes(_loc6_);
         _loc6_.clear();
         var _loc7_:uint = 8 + Math.ceil((5 + 4 * (_loc3_[8] >> 3)) / 8) + 4;
         var _loc8_:uint = 0;
         var _loc9_:ByteArray = new ByteArray();
         _loc9_.endian = Endian.LITTLE_ENDIAN;
         var _loc10_:uint = edits;
         var _loc11_:uint = emptyImportsRemoved;
         while(_loc7_ < _loc3_.length)
         {
            _loc3_.position = _loc7_;
            need(_loc3_.bytesAvailable >= 2);
            _loc12_ = _loc3_.readUnsignedShort();
            _loc13_ = uint(_loc12_ & 0x3F);
            _loc14_ = uint(_loc12_ >> 6);
            if(_loc13_ == 63)
            {
               need(_loc3_.bytesAvailable >= 4);
               _loc13_ = _loc3_.readUnsignedInt();
            }
            _loc15_ = _loc3_.position;
            _loc16_ = _loc15_ + _loc13_;
            need(_loc16_ >= _loc15_ && _loc16_ <= _loc3_.length);
            if((_loc14_ == 57 || _loc14_ == 71) && Boolean(emptyImport(_loc3_,_loc15_,_loc13_,_loc14_)))
            {
               part(_loc9_,_loc3_,_loc8_,_loc7_);
               _loc8_ = _loc16_;
               ++emptyImportsRemoved;
            }
            else if(_loc14_ == 72 || _loc14_ == 82)
            {
               _loc17_ = _loc15_;
               if(_loc14_ == 82)
               {
                  _loc17_ += 4;
                  need(_loc17_ < _loc16_);
                  while(_loc17_ < _loc16_ && Boolean(_loc3_[_loc17_]))
                  {
                     _loc17_++;
                  }
                  need(_loc17_ < _loc16_);
                  _loc17_++;
               }
               _loc18_ = new ByteArray();
               part(_loc18_,_loc3_,_loc17_,_loc16_);
               _loc19_ = edits;
               _loc20_ = abc(_loc18_,param2);
               if(_loc19_ != edits || param2)
               {
                  part(_loc9_,_loc3_,_loc8_,_loc7_);
                  _loc9_.writeShort(_loc14_ << 6 | 0x3F);
                  _loc9_.writeUnsignedInt(_loc17_ - _loc15_ + _loc20_.length);
                  part(_loc9_,_loc3_,_loc15_,_loc17_);
                  _loc9_.writeBytes(_loc20_);
                  _loc8_ = _loc16_;
               }
            }
            _loc7_ = _loc16_;
         }
         if(!param2 && _loc10_ == edits && _loc11_ == emptyImportsRemoved)
         {
            _loc3_.position = 0;
            return _loc3_;
         }
         part(_loc9_,_loc3_,_loc8_,_loc3_.length);
         _loc9_.position = 4;
         _loc9_.writeUnsignedInt(_loc9_.length);
         _loc9_.position = 0;
         return _loc9_;
      }
   }
}

