package airgame.bridge
{
   import flash.net.*;
   import flash.utils.*;
   
   public class OfficialResources
   {
      
      public static var base:String;
      
      public static var normalizedTags:uint = 0;
      
      public function OfficialResources()
      {
         super();
      }
      
      public static function normalizeIndex(param1:ByteArray) : ByteArray
      {
         var _loc8_:Object = null;
         var _loc9_:ByteArray = null;
         var _loc10_:ByteArray = null;
         var _loc11_:String = null;
         var _loc12_:String = null;
         var _loc2_:Class = RuntimeAdapter.gameDomain.getDefinition("com.tencent.morefun.naruto.file.FileAssetInfo") as Class;
         registerClassAlias("alias.com.tencent.morefun.naruto.file::FileAssetInfo",_loc2_);
         var _loc3_:ByteArray = new ByteArray();
         _loc3_.writeBytes(param1);
         _loc3_.uncompress("lzma");
         _loc3_.position = 0;
         var _loc4_:uint = _loc3_.readUnsignedInt();
         var _loc5_:uint = _loc3_.position;
         if(_loc4_ > _loc3_.bytesAvailable)
         {
            throw new Error("resource_index_size");
         }
         var _loc6_:Object = _loc3_.readObject();
         if(_loc3_.position - _loc5_ != _loc4_)
         {
            throw new Error("resource_index_encoding");
         }
         var _loc7_:uint = _loc3_.position;
         normalizedTags = 0;
         for each(_loc8_ in _loc6_)
         {
            if(_loc8_ != null && typeof _loc8_ == "object" && "tag" in _loc8_ && Boolean(_loc8_.tag))
            {
               _loc11_ = String(_loc8_.tag).replace(/\/$/,"");
               _loc12_ = resolve(_loc11_ + "/").replace(/\/$/,"");
               if(_loc12_ != _loc11_)
               {
                  _loc8_.tag = _loc12_;
                  ++normalizedTags;
               }
            }
         }
         _loc9_ = new ByteArray();
         _loc9_.writeObject(_loc6_);
         _loc10_ = new ByteArray();
         _loc10_.writeUnsignedInt(_loc9_.length);
         _loc10_.writeBytes(_loc9_);
         if(_loc7_ < _loc3_.length)
         {
            _loc10_.writeBytes(_loc3_,_loc7_,_loc3_.length - _loc7_);
         }
         _loc10_.compress("lzma");
         _loc10_.position = 0;
         return _loc10_;
      }
      
      public static function select(param1:String) : void
      {
         if(!/^https:\/\/res\.huoying\.qq\.com\/NarutoBeta[0-9.]+Build[0-9]+\/entry\.swf(?:\?|$)/.test(param1))
         {
            throw new Error("invalid_official_entry");
         }
         base = param1.split("?")[0].replace(/entry\.swf$/,"");
      }
      
      public static function resolve(param1:String) : String
      {
         if(Boolean(base) && param1 == "app:/resource.cfg")
         {
            return base + "resource.cfg";
         }
         if(/^(?:app:\/|\/?)(NarutoBeta[0-9.]+Build[0-9]+\/)/.test(param1))
         {
            param1 = "https://res.huoying.qq.com/" + param1.replace(/^(app:\/|\/)/,"");
         }
         return param1.replace(/^http:\/\/res\.huoying\.qq\.com\//,"https://res.huoying.qq.com/");
      }
      
      private static function file(param1:String) : Object
      {
         if(!/^https:\/\/res\.huoying\.qq\.com\/NarutoBeta[0-9.]+Build[0-9]+\/[A-Za-z0-9_.\/-]+$/.test(param1) || param1.indexOf("/../") >= 0)
         {
            return null;
         }
         var _loc2_:Class = getDefinitionByName("flash.filesystem.File") as Class;
         return _loc2_.applicationStorageDirectory.resolvePath("official-resources/" + param1.substr("https://res.huoying.qq.com/".length));
      }
      
      public static function read(param1:String) : ByteArray
      {
         var target:Object = null;
         var Stream:Class = null;
         var stream:Object = null;
         var bytes:ByteArray = null;
         var url:String = param1;
         try
         {
            target = file(url);
            if(!target || !target.exists || target.size <= 0 || target.size > 33554432)
            {
               return null;
            }
            Stream = getDefinitionByName("flash.filesystem.FileStream") as Class;
            stream = new Stream();
            bytes = new ByteArray();
            stream.open(target,"read");
            try
            {
               stream.readBytes(bytes);
            }
            finally
            {
               stream.close();
            }
            return bytes;
         }
         catch(error:Error)
         {
            return null;
         }
      }
      
      public static function save(param1:String, param2:ByteArray) : void
      {
         var temp:Object = null;
         var target:Object = null;
         var Stream:Class = null;
         var stream:Object = null;
         var url:String = param1;
         var bytes:ByteArray = param2;
         if(!bytes || !bytes.length || bytes.length > 33554432)
         {
            return;
         }
         try
         {
            target = file(url);
            if(!target)
            {
               return;
            }
            target.parent.createDirectory();
            temp = target.parent.resolvePath(target.name + "." + String(Math.random()).substr(2) + ".tmp");
            Stream = getDefinitionByName("flash.filesystem.FileStream") as Class;
            stream = new Stream();
            stream.open(temp,"write");
            try
            {
               stream.writeBytes(bytes);
            }
            finally
            {
               stream.close();
            }
            temp.moveTo(target,true);
         }
         catch(error:Error)
         {
            if(Boolean(temp))
            {
               try
               {
                  if(Boolean(temp.exists))
                  {
                     temp.deleteFile();
                  }
               }
               catch(ignored:Error)
               {
               }
            }
         }
      }
   }
}

