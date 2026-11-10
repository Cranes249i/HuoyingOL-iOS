package airgame.bridge
{
   import flash.events.*;
   import flash.net.*;
   import flash.utils.*;
   
   public class URLLoader extends flash.net.URLLoader
   {
      
      public static var onDiagnostic:Function;
      
      public static var diagnostics:Array = [];
      
      public static var bundledBootstrapReads:uint = 0;
      
      public static var bundledAssetReads:uint = 0;
      
      private static var active:Dictionary = new Dictionary();
      
      private static const TIMEOUT_MS:uint = 30000;
      
      private static const DNS_TIMEOUT_MS:uint = 5000;
      
      private static const RETRY_DELAY_MS:uint = 500;
      
      private var source:String;
      
      private var request:URLRequest;
      
      private var attempt:uint = 0;
      
      private var status:int = 0;
      
      private var eligible:Boolean = false;
      
      private var dnsLookup:Boolean = false;
      
      private var terminal:Boolean = false;
      
      private var cancelled:Boolean = false;
      
      private var watchdog:flash.utils.Timer;
      
      private var retryTimer:flash.utils.Timer;
      
      private var wrappers:Dictionary;
      
      public function URLLoader(param1:URLRequest = null)
      {
         var request:URLRequest = param1;
         this.wrappers = new Dictionary(true);
         super();
         super.addEventListener(Event.COMPLETE,this.complete,false,int.MAX_VALUE);
         super.addEventListener("ioError",this.failed,false,int.MAX_VALUE);
         super.addEventListener("securityError",this.failed,false,int.MAX_VALUE);
         super.addEventListener("progress",function(param1:Event):void
         {
            if((eligible || dnsLookup) && watchdog && !terminal && !cancelled)
            {
               watchdog.reset();
               watchdog.start();
            }
         });
         if(Boolean(request))
         {
            this.load(request);
         }
      }
      
      private function record(param1:String) : void
      {
         var _loc2_:Object = {
            "kind":param1,
            "url":this.source,
            "bytes":bytesLoaded,
            "attempt":this.attempt,
            "status":this.status
         };
         diagnostics.push(_loc2_);
         if(diagnostics.length > 80)
         {
            diagnostics.shift();
         }
         if(this.eligible && onDiagnostic && Boolean(/^(cached|retry|timeout|failed|index_normalized|index_invalid)$/.test(param1)))
         {
            onDiagnostic(_loc2_);
         }
      }
      
      private function stopTimers() : void
      {
         if(Boolean(this.watchdog))
         {
            this.watchdog.stop();
         }
         if(Boolean(this.retryTimer))
         {
            this.retryTimer.stop();
         }
      }
      
      private function httpStatus(param1:HTTPStatusEvent) : void
      {
         this.status = param1.status;
      }
      
      private function begin() : void
      {
         var next:URLRequest;
         var cached:ByteArray = null;
         if(this.cancelled)
         {
            return;
         }
         ++this.attempt;
         this.status = 0;
         this.record("request");
         cached = Boolean(this.eligible) && !/\/(resource\.cfg|entry\.swf)$/.test(this.source) ? OfficialResources.read(this.source) : null;
         if(Boolean(cached))
         {
            active[this] = true;
            setTimeout(function():void
            {
               if(Boolean(cancelled) || Boolean(terminal))
               {
                  return;
               }
               data = dataFormat == "binary" ? cached : cached.toString();
               record("cached");
               dispatchEvent(new Event(Event.COMPLETE));
            },0);
            return;
         }
         next = this.request;
         if(Boolean(this.eligible) || Boolean(this.dnsLookup))
         {
            active[this] = true;
            Object(next).idleTimeout = this.dnsLookup ? DNS_TIMEOUT_MS : TIMEOUT_MS;
            this.watchdog.reset();
            this.watchdog.start();
         }
         try
         {
            super.load(next);
         }
         catch(err:Error)
         {
            if(!eligible)
            {
               throw err;
            }
            if(!recover())
            {
               dispatchEvent(new IOErrorEvent("ioError",false,false,"静态资源无法打开",2032));
            }
         }
      }
      
      private function recover() : Boolean
      {
         this.stopTimers();
         if(Boolean(this.eligible) && this.attempt < 3 && !this.cancelled)
         {
            this.record("retry");
            try
            {
               super.close();
            }
            catch(ignored:Error)
            {
            }
            Object(this.request).useCache = false;
            this.retryTimer.delay = RETRY_DELAY_MS * this.attempt;
            this.retryTimer.reset();
            this.retryTimer.start();
            return true;
         }
         this.terminal = true;
         delete active[this];
         this.record("failed");
         return false;
      }
      
      private function complete(param1:Event) : void
      {
         var e:Event = param1;
         if(this.cancelled)
         {
            e.stopImmediatePropagation();
            return;
         }
         if(Boolean(this.eligible) && this.status >= 400)
         {
            e.stopImmediatePropagation();
            if(!this.recover())
            {
               dispatchEvent(new IOErrorEvent("ioError",false,false,"静态资源 HTTP 错误",2032));
            }
            return;
         }
         if(Boolean(this.eligible) && dataFormat == "binary" && data is ByteArray)
         {
            OfficialResources.save(this.source,data as ByteArray);
         }
         if(Boolean(this.eligible) && Boolean(/\/resource\.cfg$/.test(this.source)) && dataFormat == "binary")
         {
            try
            {
               data = OfficialResources.normalizeIndex(data as ByteArray);
               this.record("index_normalized");
            }
            catch(error:Error)
            {
               e.stopImmediatePropagation();
               terminal = true;
               stopTimers();
               delete active[this];
               record("index_invalid");
               dispatchEvent(new IOErrorEvent("ioError",false,false,"资源索引地址适配失败",2032));
               return;
            }
         }
         this.terminal = true;
         this.stopTimers();
         delete active[this];
         this.record("complete");
      }
      
      private function failed(param1:Event) : void
      {
         if(this.cancelled)
         {
            param1.stopImmediatePropagation();
            return;
         }
         if(this.terminal)
         {
            return;
         }
         this.record(param1.type);
         if(this.recover())
         {
            param1.stopImmediatePropagation();
         }
      }
      
      override public function addEventListener(param1:String, param2:Function, param3:Boolean = false, param4:int = 0, param5:Boolean = false) : void
      {
         var type:String = param1;
         var listener:Function = param2;
         var useCapture:Boolean = param3;
         var priority:int = param4;
         var useWeakReference:Boolean = param5;
         var key:String = type + ":" + useCapture;
         var group:Object = this.wrappers[listener];
         if(!group)
         {
            group = {};
            this.wrappers[listener] = group;
         }
         if(!group[key])
         {
            group[key] = function(param1:Event):void
            {
               var text:String = null;
               var e:Event = param1;
               try
               {
                  listener(e);
               }
               catch(err:Error)
               {
                  text = err.name + ":" + err.errorID + ":" + err.message + " " + err.getStackTrace();
                  if(/access_token|openid|skey|password|cookie/i.test(text))
                  {
                     text = err.name + ":" + err.errorID;
                  }
                  diagnostics.push({
                     "kind":"listenerError",
                     "url":source,
                     "bytes":bytesLoaded,
                     "error":text.substr(0,600)
                  });
                  throw err;
               }
            };
         }
         super.addEventListener(type,group[key],useCapture,priority,useWeakReference);
      }
      
      override public function removeEventListener(param1:String, param2:Function, param3:Boolean = false) : void
      {
         var _loc4_:Object = this.wrappers[param2];
         var _loc5_:String = param1 + ":" + param3;
         super.removeEventListener(param1,Boolean(_loc4_) && Boolean(_loc4_[_loc5_]) ? _loc4_[_loc5_] : param2,param3);
      }
      
      override public function load(param1:URLRequest) : void
      {
         var resolved:String;
         var replacement:URLRequest = null;
         var request:URLRequest = param1;
         this.stopTimers();
         delete active[this];
         resolved = OfficialResources.resolve(request.url);
         if(resolved != request.url)
         {
            replacement = new URLRequest(resolved);
            replacement.method = request.method;
            replacement.data = request.data;
            replacement.requestHeaders = request.requestHeaders;
            request = replacement;
         }
         this.request = request;
         this.attempt = 0;
         this.terminal = false;
         this.cancelled = false;
         this.source = request.url.split("?")[0];
         this.eligible = Boolean(/^https:\/\/res\.huoying\.qq\.com\/NarutoBeta[0-9.]+Build\d+\//.test(request.url)) && request.method == "GET" && request.data == null && request.requestHeaders.length == 0;
         this.dnsLookup = Boolean(/^http:\/\/182\.254\.116\.117\/d\?dn=[a-z0-9.-]+$/i.test(request.url)) && request.method == "GET" && request.data == null && request.requestHeaders.length == 0;
         super.removeEventListener("httpResponseStatus",this.httpStatus);
         if(this.eligible)
         {
            super.addEventListener("httpResponseStatus",this.httpStatus);
         }
         if((Boolean(this.eligible) || Boolean(this.dnsLookup)) && !this.watchdog)
         {
            this.watchdog = new flash.utils.Timer(TIMEOUT_MS,1);
            this.retryTimer = new flash.utils.Timer(RETRY_DELAY_MS,1);
            this.retryTimer.addEventListener("timer",function(param1:Event):void
            {
               begin();
            });
            this.watchdog.addEventListener("timer",function(param1:Event):void
            {
               record("timeout");
               try
               {
                  superClose();
               }
               catch(ignored:Error)
               {
               }
               if(!recover())
               {
                  dispatchEvent(new IOErrorEvent("ioError",false,false,"静态资源请求超时",2032));
               }
            });
         }
         if(Boolean(this.watchdog))
         {
            this.watchdog.delay = this.dnsLookup ? Number(DNS_TIMEOUT_MS) : Number(TIMEOUT_MS);
         }
         if(Boolean(this.eligible) && Boolean(/\/(resource\.cfg|entry\.swf)$/.test(this.source)))
         {
            Object(request).useCache = false;
         }
         this.begin();
      }
      
      private function superClose() : void
      {
         super.close();
      }
      
      override public function close() : void
      {
         this.cancelled = true;
         this.stopTimers();
         delete active[this];
         super.close();
      }
   }
}

