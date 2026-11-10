package airgame.bridge
{
   import flash.display.Loader;
   import flash.events.*;
   import flash.net.*;
   import flash.system.*;
   import flash.utils.*;
   
   public class Loader extends flash.display.Loader
   {
      
      public static var onDiagnostic:Function;
      
      public static var diagnostics:Array = [];
      
      private var requestLoader:flash.net.URLLoader;
      
      private var source:String = "bytes";
      
      public function Loader()
      {
         super();
         contentLoaderInfo.addEventListener(Event.INIT,function(param1:Event):void
         {
            record("init",Boolean(content) ? getQualifiedClassName(content) : null);
         });
         contentLoaderInfo.addEventListener(Event.COMPLETE,function(param1:Event):void
         {
            record("complete",null);
         });
         contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,this.error);
         contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR,this.error);
         contentLoaderInfo.uncaughtErrorEvents.addEventListener("uncaughtError",function(param1:Event):void
         {
            var _loc2_:Object = Object(param1).error;
            record("uncaught",_loc2_ is Error ? Error(_loc2_).name + ":" + Error(_loc2_).errorID + ":" + Error(_loc2_).message.replace(/\?[^\s]+/g,"?[redacted]").substr(0,250) : "event");
            param1.preventDefault();
         });
      }
      
      private function record(param1:String, param2:String) : void
      {
         var _loc3_:Object = {
            "kind":param1,
            "source":this.source,
            "detail":param2
         };
         diagnostics.push(_loc3_);
         if(diagnostics.length > 120)
         {
            diagnostics.shift();
         }
         if(onDiagnostic != null)
         {
            onDiagnostic(_loc3_);
         }
      }
      
      private function error(param1:Event) : void
      {
         this.record(param1.type,"errorID" in param1 ? String(Object(param1).errorID) : null);
      }
      
      private function permitted(param1:flash.system.LoaderContext) : flash.system.LoaderContext
      {
         var _loc2_:Class = null;
         if(!param1)
         {
            _loc2_ = getDefinitionByName("airgame.bridge.LoaderContext") as Class;
            param1 = new _loc2_(false);
         }
         if(!param1.applicationDomain)
         {
            param1.applicationDomain = new ApplicationDomain(RuntimeAdapter.gameDomain || ApplicationDomain.currentDomain);
         }
         if("allowCodeImport" in param1)
         {
            Object(param1).allowCodeImport = true;
         }
         if("allowLoadBytesCodeExecution" in param1)
         {
            Object(param1).allowLoadBytesCodeExecution = true;
         }
         return param1;
      }
      
      override public function load(param1:URLRequest, param2:flash.system.LoaderContext = null) : void
      {
         var request:URLRequest = param1;
         var context:flash.system.LoaderContext = param2;
         request.url = OfficialResources.resolve(request.url);
         this.source = request.url.split("?")[0];
         this.record("request",null);
         this.requestLoader = new flash.net.URLLoader();
         this.requestLoader.dataFormat = URLLoaderDataFormat.BINARY;
         this.requestLoader.addEventListener(IOErrorEvent.IO_ERROR,this.error);
         this.requestLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,this.error);
         this.requestLoader.addEventListener(Event.COMPLETE,function(param1:Event):void
         {
            loadBytes(requestLoader.data as ByteArray,context);
         });
         this.requestLoader.load(request);
      }
      
      override public function loadBytes(param1:ByteArray, param2:flash.system.LoaderContext = null) : void
      {
         this.record("loadBytes",String(param1.length));
         var _loc3_:Class = getDefinitionByName("airgame.bridge.RuntimeAdapter") as Class;
         super.loadBytes(_loc3_.apply(param1),this.permitted(param2));
      }
      
      override public function close() : void
      {
         if(Boolean(this.requestLoader))
         {
            try
            {
               this.requestLoader.close();
            }
            catch(e:Error)
            {
            }
         }
         super.close();
      }
      
      override public function unloadAndStop(param1:Boolean = true) : void
      {
         this.record("beforeUnload","gc=" + param1 + " root=" + (Boolean(content) ? getQualifiedClassName(content) : "null") + " hostDomain=" + (content != null && contentLoaderInfo.applicationDomain === ApplicationDomain.currentDomain));
         super.unloadAndStop(param1);
         this.record("afterUnload",null);
      }
   }
}

