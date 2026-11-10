package
{
   import flash.display.Loader;
   import flash.display.Sprite;
   import flash.display.StageAlign;
   import flash.display.StageScaleMode;
   import flash.events.ErrorEvent;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.LocationChangeEvent;
   import flash.events.SecurityErrorEvent;
   import flash.filesystem.File;
   import flash.filesystem.FileMode;
   import flash.filesystem.FileStream;
   import flash.geom.Rectangle;
   import flash.media.StageWebView;
   import flash.net.URLLoader;
   import flash.net.URLLoaderDataFormat;
   import flash.net.URLRequest;
   import flash.system.ApplicationDomain;
   import flash.system.Capabilities;
   import flash.system.LoaderContext;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.utils.ByteArray;
   import flash.utils.getQualifiedClassName;
   import flash.utils.setTimeout;

   /**
    * Simulator smoke test for the iOS-specific mechanisms the launcher relies on:
    *  1. Loader.loadBytes() of a SWF that contains ActionScript (interpreter target)
    *  2. StageWebView.loadURL("javascript:...") executing script in the page
    *  3. LocationChangeEvent.LOCATION_CHANGING delivered for a custom scheme with a long payload
    *  4. the real huoying.qq.com selection page loading inside StageWebView
    * Results are shown on screen and written to app-storage:/probe-results.txt
    */
   public class IosProbe extends Sprite
   {
      private var log:TextField;
      private var web:StageWebView;
      private var lines:Array = [];
      private var loader:Loader;

      public function IosProbe()
      {
         super();
         if(stage) init(); else addEventListener(Event.ADDED_TO_STAGE, init);
      }

      private function init(e:Event = null):void
      {
         removeEventListener(Event.ADDED_TO_STAGE, init);
         stage.scaleMode = StageScaleMode.NO_SCALE;
         stage.align = StageAlign.TOP_LEFT;
         stage.color = 0x102030;
         log = new TextField();
         log.defaultTextFormat = new TextFormat("_sans", 14, 0xFFFFFF);
         log.multiline = true;
         log.wordWrap = true;
         log.x = 8;
         log.y = 8;
         log.width = stage.stageWidth - 16;
         log.height = stage.stageHeight / 2 - 16;
         addChild(log);
         say("PROBE start runtime=" + Capabilities.version + " os=" + Capabilities.os + " stage=" + stage.stageWidth + "x" + stage.stageHeight + " dpi=" + Capabilities.screenDPI);
         loaderInfo.uncaughtErrorEvents.addEventListener("uncaughtError", function(ev:Event):void
         {
            var err:Object = Object(ev).error;
            say("UNCAUGHT " + (err is Error ? Error(err).name + " #" + Error(err).errorID + " " + Error(err).message : String(err)));
            ev.preventDefault();
         });
         testLoadBytes();
         testWebView();
         setTimeout(function():void { say("PROBE done"); }, 45000);
      }

      private function say(s:String):void
      {
         trace("[PROBE] " + s);
         lines.push(s);
         log.text = lines.join("\n");
         try
         {
            var f:File = File.applicationStorageDirectory.resolvePath("probe-results.txt");
            var fs:FileStream = new FileStream();
            fs.open(f, FileMode.WRITE);
            fs.writeUTFBytes(lines.join("\n") + "\n");
            fs.close();
         }
         catch(err:Error)
         {
            trace("[PROBE] file write failed " + err.message);
         }
      }

      private function testLoadBytes():void
      {
         var ul:URLLoader = new URLLoader();
         ul.dataFormat = URLLoaderDataFormat.BINARY;
         ul.addEventListener(IOErrorEvent.IO_ERROR, function(ev:IOErrorEvent):void { say("T1 read Probe2.swf failed " + ev.text); });
         ul.addEventListener(Event.COMPLETE, function(ev:Event):void
         {
            var bytes:ByteArray = ul.data as ByteArray;
            say("T1 Probe2.swf bytes=" + bytes.length);
            loader = new Loader();
            var ctx:LoaderContext = new LoaderContext(false, new ApplicationDomain(ApplicationDomain.currentDomain));
            ctx.allowCodeImport = true;
            loader.contentLoaderInfo.addEventListener(Event.INIT, function(ev2:Event):void
            {
               var content:Object = loader.content;
               var reply:String = "n/a";
               try { reply = String(content.ping(21)); } catch(err:Error) { reply = "ping threw " + err.message; }
               say("T1 loadBytes INIT content=" + getQualifiedClassName(content) + " ping(21)=" + reply + (reply == "42" ? " => LOADED CODE RUNS: PASS" : " => FAIL"));
            });
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(ev2:Event):void { say("T1 loadBytes COMPLETE"); });
            loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(ev2:IOErrorEvent):void { say("T1 loadBytes IO_ERROR " + ev2.errorID + " " + ev2.text + " => FAIL"); });
            loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(ev2:SecurityErrorEvent):void { say("T1 loadBytes SECURITY_ERROR " + ev2.errorID + " " + ev2.text + " => FAIL"); });
            try
            {
               loader.loadBytes(bytes, ctx);
            }
            catch(err:Error)
            {
               say("T1 loadBytes THREW " + err.name + " #" + err.errorID + " " + err.message + " => FAIL");
            }
         });
         ul.load(new URLRequest("app:/Probe2.swf"));
      }

      private function testWebView():void
      {
         var jsSent:Boolean = false;
         var reports:int = 0;
         web = new StageWebView(true);
         web.stage = stage;
         web.viewPort = new Rectangle(0, int(stage.stageHeight * 0.3), stage.stageWidth, int(stage.stageHeight * 0.7));
         // Same frame-rewrite script as the launcher (MobileGame.pcLoginScript), kept in sync by hand.
         var fixJs:String = "(function(){if(window.__airPcLogin)return;window.__airPcLogin=1;" +
            "var graph='https://graph.qq.com',seen=0,noted={};" +
            "function note(t){if(noted[t])return;noted[t]=1;try{location.href='huoyingair-note:'+encodeURIComponent(t);}catch(e){}}" +
            "function scan(doc,acc){var list=doc.querySelectorAll('iframe');for(var i=0;i<list.length;i++){var f=list[i];acc.push(f);try{var d=f.contentDocument;if(d&&d.querySelectorAll)scan(d,acc);}catch(e){}}return acc;}" +
            "function fix(){var frames=scan(document,[]);" +
            "for(var i=0;i<frames.length;i++){var f=frames[i],u;" +
            "try{u=new URL(f.getAttribute('src')||'',location.href);}catch(e){continue;}" +
            "if(u.origin===graph){seen=1;" +
            "if(f.getAttribute('data-air-pc'))continue;f.setAttribute('data-air-pc','1');" +
            "if(u.pathname==='/oauth2.0/authorize'||(u.pathname==='/oauth2.0/show'&&u.searchParams.get('display')!=='pc')){" +
            "u.pathname='/oauth2.0/show';u.searchParams.set('which','Login');u.searchParams.set('display','pc');f.src=u.href;}" +
            "note('graph frame rewritten to pc show');}" +
            "else if(u.hostname==='xui.ptlogin2.qq.com'&&u.searchParams.get('appid')==='21000501'){note('plain ptlogin box (appid 21000501) detected');}}}" +
            "setInterval(fix,300);" +
            "setTimeout(function(){var un=document.getElementById('unlogin');if(!seen&&un&&un.offsetParent!==null)note('no graph frame after 15s, user must tap login');},15000);})()";
         // Reporter: enumerate iframes (src attribute, size, same-origin current href) and hand the JSON back via a custom scheme.
         var reportJs:String = "(function(){var out=[];function scan(doc,depth){var list=doc.querySelectorAll('iframe');for(var i=0;i<list.length;i++){var f=list[i],r=f.getBoundingClientRect(),cur='';" +
            "try{cur=f.contentWindow.location.href;}catch(e){cur='(x-origin)';}" +
            "out.push({d:depth,src:String(f.getAttribute('src')||'').substr(0,160),cur:String(cur).substr(0,160),w:Math.round(r.width),h:Math.round(r.height),pc:f.getAttribute('data-air-pc')||''});" +
            "try{var cd=f.contentDocument;if(cd)scan(cd,depth+1);}catch(e){}}}scan(document,0);" +
            "var un=document.getElementById('unlogin');location.href='probe-scheme:'+encodeURIComponent(JSON.stringify({t:document.title,un:un?un.offsetParent!==null:null,f:out}));})()";
         web.addEventListener(LocationChangeEvent.LOCATION_CHANGING, function(ev:LocationChangeEvent):void
         {
            var loc:String = ev.location;
            if(loc.indexOf("probe-scheme:") == 0)
            {
               ev.preventDefault();
               say("T3 custom scheme intercepted via LOCATION_CHANGING len=" + loc.length);
               return;
            }
            if(loc.indexOf("wtloginmqq:") == 0 || loc.indexOf("mqq") == 0)
            {
               ev.preventDefault();
               say("T3b qq scheme intercepted " + loc.substr(0, 60));
               return;
            }
            say("locationChanging " + loc.substr(0, 300));
         });
         web.addEventListener(LocationChangeEvent.LOCATION_CHANGE, function(ev:LocationChangeEvent):void
         {
            say("locationChange " + ev.location.substr(0, 120));
         });
         web.addEventListener(Event.COMPLETE, function(ev:Event):void
         {
            say("T4 web complete " + String(web.location).substr(0, 90) + (String(web.location).indexOf("huoying.qq.com") >= 0 ? " => PASS" : ""));
            if(jsSent) return;
            jsSent = true;
            setTimeout(function():void { say("T5 report before fix"); web.loadURL("javascript:" + reportJs); }, 1500);
            setTimeout(function():void { say("T5 applying frame fix"); web.loadURL("javascript:" + fixJs); }, 3000);
            var later:Function = function():void
            {
               if(++reports > 6) return;
               say("T5 report #" + reports + " location=" + String(web.location).substr(0, 60));
               web.loadURL("javascript:" + reportJs);
               setTimeout(later, 6000);
            };
            setTimeout(later, 6000);
         });
         web.addEventListener(ErrorEvent.ERROR, function(ev:ErrorEvent):void
         {
            var text:String = String(ev.text);
            var noteAt:int = text.indexOf("huoyingair-note:");
            if(noteAt >= 0)
            {
               var noteText:String = "";
               try { noteText = decodeURIComponent(text.substr(noteAt + "huoyingair-note:".length)); } catch(err2:Error) { noteText = text.substr(noteAt, 200); }
               say("T5 note " + noteText);
               return;
            }
            var at:int = text.indexOf("probe-scheme:");
            if(at >= 0)
            {
               var json:String = "";
               try { json = decodeURIComponent(text.substr(at + "probe-scheme:".length)); } catch(err:Error) { json = "(decode failed) " + text.substr(at, 200); }
               say("T5 frames " + json.substr(0, 1500));
               return;
            }
            say("T4 web error " + text.substr(0, 300));
         });
         say("T4 loading https://huoying.qq.com/server/website/");
         web.loadURL("https://huoying.qq.com/server/website/");
      }
   }
}
