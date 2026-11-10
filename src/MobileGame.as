package
{
   import airgame.bridge.EntryCompatibility;
   import airgame.bridge.ExternalInterface;
   import airgame.bridge.GameBridge;
   import airgame.bridge.Loader;
   import airgame.bridge.LoaderContext;
   import airgame.bridge.OfficialResources;
   import airgame.bridge.RuntimeAdapter;
   import airgame.bridge.Security;
   import airgame.bridge.Socket;
   import airgame.bridge.SpeedClock;
   import airgame.bridge.Timer;
   import airgame.bridge.URLLoader;
   import airgame.bridge.getTimer;
   import flash.crypto.*;
   import flash.display.*;
   import flash.events.*;
   import flash.geom.*;
   import flash.net.*;
   import flash.system.*;
   import flash.text.*;
   import flash.utils.*;
   
   public class MobileGame extends Sprite
   {
      
      public static var instance:MobileGame;
      
      private static const LOG_LIMIT:int = 512 * 1024;
      
      public static var playersHidden:Boolean = false;
      
      public static var appTicks:uint = 0;
      
      public static var appActive:Boolean = true;
      
      public static var backgroundServiceRunning:Boolean = false;
      
      private var nativeApp:Object;
      
      private var iosTest:Boolean = false;
      
      private var sessionProbe:String;
      
      private var browser:Object;
      
      private var loader:flash.display.Loader;
      
      private var status:TextField = new TextField();
      
      private var poll:flash.utils.Timer = new flash.utils.Timer(1000);
      
      private static const LINKED_BRIDGE:Array = [airgame.bridge.EntryCompatibility,airgame.bridge.ExternalInterface,airgame.bridge.GameBridge,airgame.bridge.Loader,airgame.bridge.LoaderContext,airgame.bridge.OfficialResources,airgame.bridge.RuntimeAdapter,airgame.bridge.Security,airgame.bridge.Socket,airgame.bridge.SpeedClock,airgame.bridge.Timer,airgame.bridge.URLLoader,airgame.bridge.getTimer];
      
      private var loginFixLocation:String = "";
      
      private var completedLocation:String = "";
      
      private var loginFixTicks:uint = 0;
      
      private var navBar:Sprite;
      
      private var qcState:String = "";
      
      private var qcAppId:String = "";
      
      private var qcRedirect:String = "";
      
      private var pendingQcCode:String = "";
      
      private var qcHandoffTime:Number = 0;
      
      private var trusted:Boolean = false;
      
      private var started:Boolean = false;
      
      private var session:Object;
      
      private var output:Object;
      
      private var file:Object;
      
      private var downloading:flash.net.URLLoader;
      
      private var samples:uint = 0;
      
      private var gameReady:Boolean = false;
      
      private var qq:Object;
      
      private var qqReady:Boolean = false;
      
      private var loginScript:flash.net.URLLoader;
      
      private var loginMode:String;
      
      private var microLogin:Boolean = false;
      
      private var sessionWaitStart:Number = 0;
      
      private var sessionWaitHint:Boolean = false;
      
      private var sessionFailure:String;
      
      private var bridgeKey:String = String(new Date().time) + "-" + Math.random() + "-" + Math.random();
      
      private var controlReceived:uint = 0;
      
      private var resizePending:Boolean = false;
      
      private var desiredSpeed:Number = 1;
      
      private var lastIdentity:String = "";
      
      public function MobileGame()
      {
         super();
         instance = this;
         if(Boolean(stage))
         {
            this.init();
         }
         else
         {
            addEventListener(Event.ADDED_TO_STAGE,this.init);
         }
      }
      
      private function init(param1:Event = null) : void
      {
         var descriptor:XML;
         var e:Event = param1;
         removeEventListener(Event.ADDED_TO_STAGE,this.init);
         stage.scaleMode = "noScale";
         stage.align = "TL";
         stage.frameRate = 31;
         stage.color = 1120295;
         try
         {
            stage.displayState = "fullScreenInteractive";
         }
         catch(error:Error)
         {
         }
         stage.addEventListener(Event.RESIZE,this.layout,false,10000);
         stage.addEventListener(Event.ENTER_FRAME,this.hidePlayers,false,10000);
         stage.addEventListener(KeyboardEvent.KEY_DOWN,function(param1:KeyboardEvent):void
         {
            if(Boolean(started) && (param1.keyCode == 16777238 || param1.keyCode == 4 || param1.keyCode == 27))
            {
               param1.preventDefault();
               param1.stopImmediatePropagation();
               if(qqReady)
               {
                  qq.call("returnToSelection");
               }
            }
         },true,1000);
         this.status.defaultTextFormat = new TextFormat("_sans",18,16777215);
         this.status.width = 1000;
         this.status.height = 42;
         this.status.y = 3;
         this.status.x = 12;
         this.status.mouseEnabled = false;
         addChild(this.status);
         this.nativeApp = Object(getDefinitionByName("flash.desktop.NativeApplication")).nativeApplication;
         descriptor = this.nativeApp.applicationDescriptor;
         this.iosTest = descriptor.child(new QName(descriptor.namespace(),"iPhone")).length() > 0;
         if(this.iosTest)
         {
            this.status.selectable = false;
            this.status.mouseEnabled = true;
            this.status.wordWrap = true;
            this.status.addEventListener(MouseEvent.CLICK,function(param1:MouseEvent):void
            {
               if(!started)
               {
                  openLogin();
               }
            });
            this.buildNav();
         }
         this.nativeApp.addEventListener(Event.ACTIVATE,function(param1:Event):void
         {
            appActive = true;
            if(started)
            {
               resizePending = true;
            }
            record("生命周期 activate ticks=" + appTicks);
         });
         this.nativeApp.addEventListener(Event.DEACTIVATE,function(param1:Event):void
         {
            appActive = false;
            if(started)
            {
               resizePending = true;
            }
            record("生命周期 deactivate ticks=" + appTicks);
         });
         Object(getDefinitionByName("airgame.bridge.RuntimeAdapter")).redirectNet = true;
         Object(getDefinitionByName("airgame.bridge.RuntimeAdapter")).redirectTime = true;
         Object(getDefinitionByName("airgame.bridge.Loader")).onDiagnostic = function(param1:Object):void
         {
            record("模块执行 " + param1.kind + " " + param1.source + " " + param1.detail);
         };
         Object(getDefinitionByName("airgame.bridge.URLLoader")).onDiagnostic = function(param1:Object):void
         {
            report("文件 " + param1.kind + " " + param1.url + " attempt=" + param1.attempt + " status=" + param1.status);
         };
         this.report("火影OL · 正在初始化");
         loaderInfo.uncaughtErrorEvents.addEventListener("uncaughtError",function(param1:Event):void
         {
            var _loc2_:Object = Object(param1).error;
            var _loc3_:String = _loc2_ is Error ? Error(_loc2_).message : "";
            if(/access_token|openid|password|cookie|skey/i.test(_loc3_))
            {
               _loc3_ = "";
            }
            report("运行错误 " + (_loc2_ is Error ? Error(_loc2_).name + " #" + Error(_loc2_).errorID : "event") + " " + _loc3_.replace(/https?:\/\/[^\s]+/g,"[URL]").substr(0,100));
            if(_loc2_ is Error && Boolean(Error(_loc2_).getStackTrace()))
            {
               report(Error(_loc2_).getStackTrace().replace(/https?:\/\/[^\s]+/g,"[URL]").substr(0,180));
            }
            param1.preventDefault();
         });
         this.poll.addEventListener("timer",this.inspect);
         this.poll.start();
         this.openLogin();
         this.layout();
      }
      
      private function layout(param1:Event = null) : void
      {
         if(Boolean(this.started) && (!appActive || Boolean(this.resizePending)))
         {
            if(Boolean(param1))
            {
               param1.stopImmediatePropagation();
            }
            this.record("后台尺寸延后 " + stage.stageWidth + "x" + stage.stageHeight + " active=" + appActive);
            return;
         }
         this.status.width = Math.max(100,stage.stageWidth - 16);
         if(!this.iosTest)
         {
            if(Boolean(this.browser) && !this.started)
            {
               this.browser.viewPort = new Rectangle(0,0,stage.stageWidth,Math.max(1,stage.stageHeight));
            }
            return;
         }
         if(stage.stageWidth < 2 || stage.stageHeight < 8)
         {
            return;
         }
         var _loc2_:int = Math.min(stage.stageHeight - 1,Math.max(38,int(stage.stageHeight * 0.11)));
         var _loc3_:int = int(stage.stageWidth * 0.06);
         var navWidth:int = this.layoutNav(_loc2_,_loc3_);
         this.status.x = _loc3_;
         this.status.width = Math.max(80,stage.stageWidth - 2 * _loc3_ - navWidth);
         this.status.height = _loc2_ - 3;
         this.status.defaultTextFormat = new TextFormat("_sans",Math.max(15,int(_loc2_ * 0.34)),16777215);
         if(Boolean(this.status.length))
         {
            this.status.setTextFormat(this.status.defaultTextFormat);
         }
         if(Boolean(this.browser) && !this.started)
         {
            this.browser.viewPort = new Rectangle(_loc3_,_loc2_,stage.stageWidth - 2 * _loc3_,stage.stageHeight - _loc2_);
         }
      }
      
      private function buildNav() : void
      {
         var labels:Array = ["后退","前进","刷新","选区"];
         var i:int = 0;
         var btn:Sprite = null;
         var label:TextField = null;
         if(Boolean(this.navBar))
         {
            return;
         }
         this.navBar = new Sprite();
         while(i < labels.length)
         {
            btn = new Sprite();
            btn.name = "nav" + i;
            btn.buttonMode = true;
            btn.mouseChildren = false;
            label = new TextField();
            label.name = "label";
            label.selectable = false;
            label.mouseEnabled = false;
            label.text = labels[i];
            btn.addChild(label);
            btn.addEventListener(MouseEvent.CLICK,this.navClick);
            this.navBar.addChild(btn);
            i++;
         }
         addChild(this.navBar);
      }
      
      private function layoutNav(stripHeight:int, margin:int) : int
      {
         var i:int = 0;
         var btn:Sprite = null;
         var label:TextField = null;
         var total:int = 0;
         var h:int = Math.max(28,stripHeight - 8);
         var w:int = int(h * 1.8);
         var gap:int = 6;
         if(!this.navBar)
         {
            return 0;
         }
         this.navBar.visible = Boolean(this.iosTest) && !this.started && Boolean(this.browser);
         while(i < this.navBar.numChildren)
         {
            btn = this.navBar.getChildAt(i) as Sprite;
            btn.x = i * (w + gap);
            btn.y = 0;
            btn.graphics.clear();
            btn.graphics.beginFill(0x2E6CDF,0.95);
            btn.graphics.drawRoundRect(0,0,w,h,10,10);
            btn.graphics.endFill();
            label = btn.getChildByName("label") as TextField;
            label.width = w;
            label.height = h;
            label.defaultTextFormat = new TextFormat("_sans",Math.max(13,int(h * 0.42)),16777215,true,null,null,null,null,"center");
            label.setTextFormat(label.defaultTextFormat);
            label.y = Math.max(0,int((h - label.textHeight) / 2) - 2);
            i++;
         }
         total = this.navBar.numChildren * w + (this.navBar.numChildren - 1) * gap;
         this.navBar.x = stage.stageWidth - margin - total;
         this.navBar.y = int((stripHeight - h) / 2);
         return total + 10;
      }
      
      private function navClick(param1:MouseEvent) : void
      {
         var index:int = int(String(param1.currentTarget.name).substr(3));
         if(!this.browser || Boolean(this.started))
         {
            return;
         }
         try
         {
            if(index == 0)
            {
               if(this.browser.isHistoryBackEnabled)
               {
                  this.browser.historyBack();
               }
               else
               {
                  this.report("没有可后退的页面");
               }
            }
            else if(index == 1)
            {
               if(this.browser.isHistoryForwardEnabled)
               {
                  this.browser.historyForward();
               }
               else
               {
                  this.report("没有可前进的页面");
               }
            }
            else if(index == 2)
            {
               this.browser.reload();
               this.report("正在刷新当前页");
            }
            else
            {
               this.loadLogin();
            }
         }
         catch(err:Error)
         {
            this.report("页面操作失败 " + err.message.substr(0,60));
         }
      }
      
      private function report(param1:String) : void
      {
         if(!/^(文件 |模块 |资源读取 |内置资源索引 |索引解码 |入口容器 |入口初始化 )/.test(param1))
         {
            this.status.text = Boolean(this.iosTest) && !this.started ? "重载选区 · " + param1 : param1;
         }
         this.record(param1);
      }
      
      private function record(param1:String) : void
      {
         var _loc2_:Class = null;
         var _loc3_:Class = null;
         var _loc4_:Object = null;
         try
         {
            if(Boolean(this.output) && (this.output.position >= LOG_LIMIT || !this.file.exists))
            {
               this.output.close();
               this.output = null;
            }
            if(!this.output)
            {
               _loc2_ = getDefinitionByName("flash.filesystem.File") as Class;
               _loc3_ = getDefinitionByName("flash.filesystem.FileStream") as Class;
               this.file = _loc2_.applicationStorageDirectory.resolvePath("air-diagnostics-" + String(new Date().time) + "-" + String(100000 + int(Math.random() * 900000)) + ".jsonl");
               _loc4_ = new _loc3_();
               _loc4_.open(this.file,"append");
               this.output = _loc4_;
            }
            this.output.writeUTFBytes(JSON.stringify({
               "time":new Date().time,
               "event":param1.substr(0,180)
            }) + "\n");
         }
         catch(err:Error)
         {
         }
         if(Boolean(this.qq))
         {
            try
            {
               this.qq.call("diagnostic",param1.substr(0,180));
            }
            catch(nativeLogError:Error)
            {
            }
         }
      }
      
      private function openLogin(param1:String = null) : void
      {
         var Type:Class = null;
         var mode:String = param1;
         this.record("登录入口 started=" + this.started + " native=" + this.qqReady + " stage=" + stage.stageWidth + "x" + stage.stageHeight);
         if(this.started)
         {
            return;
         }
         this.loginMode = mode;
         this.sessionWaitStart = 0;
         this.sessionWaitHint = false;
         this.sessionFailure = null;
         this.sessionProbe = null;
         if(!this.browser)
         {
            Type = getDefinitionByName("flash.media.StageWebView") as Class;
            this.browser = new Type(true);
            this.browser.addEventListener("locationChanging",this.locationChanging);
            this.browser.addEventListener("complete",this.pageComplete);
            this.browser.addEventListener("error",function(param1:Event):void
            {
               if(iosTest && webErrorAsScheme(String(Object(param1).text)))
               {
                  return;
               }
               loginIssue("登录网页加载失败，可重启当前账号后重试",true);
            });
         }
         this.trusted = false;
         this.browser.stage = stage;
         this.layout();
         if(this.iosTest)
         {
            this.loadLogin();
            return;
         }
         if(this.qqReady)
         {
            this.loadLogin();
            return;
         }
         if(Boolean(this.qq))
         {
            this.loadLogin();
            return;
         }
         try
         {
            this.qq = Object(getDefinitionByName("QqAirLib")).create();
            if(!this.qq)
            {
               throw new Error("QQ_native_unavailable");
            }
            if(this.qq.call("licenseActive") !== true)
            {
               this.report("请先激活火影OL");
               return;
            }
            this.microLogin = this.qq.call("microLogin") === true;
            this.qq.addEventListener("status",function(param1:Event):void
            {
               var _loc2_:String = Object(param1).code;
               if(_loc2_ == "host_resumed")
               {
                  appActive = true;
                  if(started)
                  {
                     nativeApp.executeInBackground = true;
                     resizePending = false;
                     stage.dispatchEvent(new Event(Event.RESIZE));
                  }
                  layout();
                  record("宿主焦点和尺寸已恢复");
                  return;
               }
               if(_loc2_ == "speed_changed")
               {
                  desiredSpeed = Number(Object(param1).level);
                  applySpeed();
                  return;
               }
               if(_loc2_ == "selection_requested")
               {
                  if(started)
                  {
                     qq.call("returnToSelection");
                  }
                  else
                  {
                     openLogin();
                  }
                  return;
               }
               if(_loc2_ == "login_requested")
               {
                  if(!started)
                  {
                     openLogin(String(Object(param1).level));
                  }
                  else
                  {
                     report("请先返回选区再切换登录方式");
                  }
                  return;
               }
               if(_loc2_ == "game_control")
               {
                  control(String(Object(param1).level));
                  return;
               }
               if(_loc2_ == "game_session")
               {
                  acceptSession(String(Object(param1).level),true);
                  return;
               }
               if(_loc2_ == "background_state")
               {
                  record("后台联网 " + String(Object(param1).level) + " ticks=" + appTicks);
                  return;
               }
               if(_loc2_ == "qq_ready")
               {
                  qqReady = true;
                  loadLogin();
               }
               else if(_loc2_ == "qq_launched")
               {
                  report("已打开手机 QQ，请选择账号并授权");
               }
               else if(_loc2_ == "qq_returned")
               {
                  report(microLogin ? "QQ 授权已返回，正在完成微端登录" : "QQ 授权已返回，正在完成网页登录");
               }
               else if(_loc2_ == "background_started")
               {
                  backgroundServiceRunning = true;
               }
               else if(_loc2_ == "background_stopped")
               {
                  backgroundServiceRunning = false;
               }
               else if(_loc2_ == "qq_link_setup")
               {
                  report("请允许登录链接返回火影OL，完成后返回应用");
               }
               else if(_loc2_ == "qq_native_error")
               {
                  qqReady = false;
                  loadLogin();
                  loginIssue("QQ 登录组件暂不可用，可在官网页面登录");
               }
               else if(_loc2_ == "qq_launch_failed" || _loc2_ == "qq_request_rejected" || _loc2_ == "qq_return_not_accepted")
               {
                  report("QQ 登录尚未完成，请重新发起或使用网页登录");
               }
               record(_loc2_);
            });
            this.loginScript = new flash.net.URLLoader();
            this.loginScript.addEventListener(Event.COMPLETE,function(param1:Event):void
            {
               qq.call("install",String(loginScript.data),microLogin ? microFrameCapture() : "");
            });
            this.loginScript.addEventListener("ioError",function(param1:Event):void
            {
               loadLogin();
               loginIssue("QQ 登录组件读取失败，可在官网页面登录");
            });
            this.loginScript.load(new URLRequest("app:/qq-return.js"));
         }
         catch(error:Error)
         {
            qq = null;
            report("QQ 组件初始化 " + error.name + " #" + error.errorID + " " + error.message.substr(0,80));
            loadLogin();
         }
      }
      
      private function loginIssue(param1:String, param2:Boolean = false) : void
      {
         this.report(param1);
         if(Boolean(this.qq))
         {
            try
            {
               this.qq.call("loginNotice",param1,param2 ? "restart" : "");
            }
            catch(error:Error)
            {
            }
         }
      }
      
      private function loadLogin() : void
      {
         if(this.microLogin)
         {
            if(Boolean(this.loginMode) && Boolean(this.qqReady))
            {
               this.qq.call("mode",this.loginMode);
            }
            else if(!this.qqReady || this.qq.call("microSelection") !== true)
            {
               this.browser.loadURL("https://minigame.qq.com/plat/social_hall/app_frame/index_v4.html?appid=1103286479");
            }
            this.report("微端 · 如需登录，请点顶部登录");
            return;
         }
         if(Boolean(this.loginMode) && Boolean(this.qqReady))
         {
            this.qq.call("mode",this.loginMode);
         }
         else
         {
            this.browser.loadURL("https://huoying.qq.com/server/website/");
         }
         this.report(this.iosTest ? "请在登录框点「密码登录」输入 QQ 账号密码，登录后选择区服" : "请登录 QQ 并选择区服，随后进入游戏");
      }
      
      private function pageComplete(param1:Event) : void
      {
         var e:Event = param1;
         var code:String = null;
         try
         {
            this.completedLocation = String(this.browser.location);
            this.trusted = /^https:\/\/game\.huoying\.qq\.com\//.test(this.completedLocation);
         }
         catch(err:Error)
         {
            completedLocation = "";
            trusted = false;
         }
         this.loginFixLocation = "";
         this.loginFixTicks = 0;
         this.record("登录网页 complete " + this.completedLocation.substr(0,80));
         if(Boolean(this.iosTest) && !this.started && this.completedLocation.length > 0)
         {
            if(/^https:\/\/huoying\.qq\.com\/comm-htdocs\/login\/(qc_redirect|qccallback)\.html\?/.test(this.completedLocation) && Boolean(this.queryParam(this.completedLocation,"code")))
            {
               this.qcCodeArrived(this.completedLocation);
               return;
            }
            if(Boolean(this.pendingQcCode) && /^https:\/\/huoying\.qq\.com\//.test(this.completedLocation))
            {
               code = this.pendingQcCode;
               this.pendingQcCode = "";
               this.browser.loadURL("javascript:" + this.qcExchangeScript(code));
            }
         }
         this.inspect();
      }
      
      private function hidePlayers(param1:Event = null) : void
      {
         if(!this.started || playersHidden)
         {
            return;
         }
         playersHidden = GameBridge.hideOtherPlayers(stage);
         if(playersHidden)
         {
            stage.removeEventListener(Event.ENTER_FRAME,this.hidePlayers);
            this.record("玩家屏蔽已确认");
         }
      }
      
      private function inspect(param1:Event = null) : void
      {
         var app:Object = null;
         var identity:Object = null;
         var label:String = null;
         var diag:Object = null;
         var row:Object = null;
         var random:ByteArray = null;
         var i:int = 0;
         var e:Event = param1;
         if(Boolean(e) && e.type == "timer")
         {
            ++appTicks;
         }
         if(this.started)
         {
            this.hidePlayers();
            if(!appActive)
            {
               return;
            }
            if(Boolean(this.resizePending) && stage.stageWidth > 0 && stage.stageHeight > 0)
            {
               this.resizePending = false;
               stage.dispatchEvent(new Event(Event.RESIZE));
               this.record("前台尺寸恢复 " + stage.stageWidth + "x" + stage.stageHeight);
            }
            if(parent === stage)
            {
               stage.setChildIndex(this,stage.numChildren - 1);
            }
            if(!this.gameReady)
            {
               try
               {
                  app = Object(Object(getDefinitionByName("airgame.bridge.RuntimeAdapter")).gameDomain.getDefinition("base.ApplicationData")).singleton;
                  if(Boolean(app.selfInfo) && app.selfInfo.level > 0)
                  {
                     this.gameReady = true;
                     this.applySpeed();
                     this.status.visible = false;
                     this.report("主城角色数据已就绪");
                  }
               }
               catch(error:Error)
               {
               }
            }
            if(Boolean(this.gameReady) && Boolean(this.qqReady))
            {
               try
               {
                  identity = Object(Object(getDefinitionByName("airgame.bridge.RuntimeAdapter")).gameDomain.getDefinition("base.ApplicationData")).singleton;
                  label = String(identity.selfuin) + "|" + String(identity.selfSrv) + "|" + String(identity.selfInfo.name);
                  if(label != this.lastIdentity)
                  {
                     this.lastIdentity = label;
                     this.qq.call("identity",String(identity.selfuin),String(identity.selfSrv),String(identity.selfInfo.name));
                  }
               }
               catch(identityError:Error)
               {
               }
            }
            if(++this.samples % 10 == 0 && this.samples <= 120)
            {
               this.report("资源读取 " + this.downloading.bytesLoaded + "/" + this.downloading.bytesTotal);
               diag = Object(getDefinitionByName("airgame.bridge.Loader")).diagnostics;
               for each(row in diag.slice(-3))
               {
                  this.report("模块 " + row.kind + " " + row.source + " " + row.detail);
               }
               diag = Object(getDefinitionByName("airgame.bridge.URLLoader")).diagnostics;
               for each(row in diag.slice(-6))
               {
                  this.report("文件 " + row.kind + " " + row.url + " " + row.bytes + " " + (row.error || ""));
               }
            }
            return;
         }
         if(!this.browser || Boolean(this.iosTest) && !appActive)
         {
            return;
         }
         try
         {
            if(!/^https:\/\/game\.huoying\.qq\.com\//.test(this.browser.location))
            {
               this.sessionWaitStart = 0;
               this.sessionWaitHint = false;
               this.sessionFailure = null;
               if(this.iosTest)
               {
                  this.trusted = false;
                  this.sessionProbe = null;
                  this.iosLoginFix();
               }
               return;
            }
            this.trusted = true;
            if(!this.sessionWaitStart)
            {
               this.sessionWaitStart = new Date().time;
            }
            if(!this.sessionWaitHint && new Date().time - this.sessionWaitStart >= 15000)
            {
               this.sessionWaitHint = true;
               this.loginIssue("选区后未收到登录信息，可重启当前账号后重试",true);
            }
            if(Boolean(this.iosTest) && !this.sessionProbe)
            {
               random = generateRandomBytes(16);
               this.sessionProbe = "";
               i = 0;
               while(i < random.length)
               {
                  this.sessionProbe += ("0" + uint(random[i]).toString(16)).substr(-2);
                  i++;
               }
            }
            if(Boolean(this.iosTest) && String(this.browser.location) != this.completedLocation)
            {
               return;
            }
            this.browser.loadURL("javascript:(function(){var packet=" + this.sessionCapture(this.sessionProbe,this.microLogin) + ";if(packet)location.href=packet;})()");
         }
         catch(err:Error)
         {
            report("登录信息尚未就绪");
         }
      }
      
      private function iosLoginFix() : void
      {
         var loc:String = null;
         try
         {
            loc = String(this.browser.location);
         }
         catch(err:Error)
         {
            return;
         }
         if(!/^https:\/\/huoying\.qq\.com\//.test(loc) || loc != this.completedLocation)
         {
            this.loginFixLocation = "";
            return;
         }
         if(loc != this.loginFixLocation)
         {
            this.loginFixLocation = loc;
            this.loginFixTicks = 0;
            this.record("iOS 登录框改走 PC 版入口");
         }
         else
         {
            if(this.loginFixTicks >= 10)
            {
               return;
            }
            if(++this.loginFixTicks % 5 != 0)
            {
               return;
            }
         }
         this.browser.loadURL("javascript:" + this.pcLoginScript());
      }
      
      private function webErrorAsScheme(param1:String) : Boolean
      {
         var text:String = param1;
         var schemes:Array = ["huoyingair-session:","huoyingair-control:","wtloginmqq:","huoyingair-note:","huoyingair-qc:"];
         var i:int = 0;
         var at:int = 0;
         var url:String = null;
         while(i < schemes.length)
         {
            at = text.indexOf(schemes[i]);
            if(at >= 0)
            {
               url = text.substr(at).replace(/[\s\r\n]+$/,"");
               if(i == 0)
               {
                  this.record("iOS 会话包经错误事件接收 " + url.length);
                  this.acceptSession(url);
               }
               else if(i == 1)
               {
                  this.control(url);
               }
               else if(i == 2)
               {
                  this.report("iOS 不支持调起手机 QQ，请在登录框点「密码登录」");
               }
               else if(i == 4)
               {
                  this.qcHandoff(url);
               }
               else
               {
                  this.webNote(url);
               }
               return true;
            }
            i++;
         }
         return false;
      }
      
      private function webNote(param1:String) : void
      {
         var text:String = "";
         try
         {
            text = decodeURIComponent(param1.substr("huoyingair-note:".length));
         }
         catch(err:Error)
         {
            return;
         }
         text = text.replace(/[\r\n]+/g," ").substr(0,80);
         if(text.length > 0)
         {
            this.report(text);
         }
      }
      
      private function pcLoginScript() : String
      {
         // The site (qqconn.js + milo biz/login) always logs in through QQ Connect: LoginManager.qcLogin opens a
         // graph.qq.com/oauth2.0/authorize iframe. Inside WKWebView that frame lands on Tencent's mobile templates (the
         // one-key page that needs the QQ app, or a password page that dies with "s_url参数丢失"), and redirects inside the
         // iframe can be neither observed nor fixed from the parent page. The page script therefore only detects the login
         // frame (or the plain ptlogin box opened before QC init, appid 21000501), blanks it and hands its URL to the
         // launcher through huoyingair-qc:; the launcher loads the PC authorize page top-level and completes the OAuth
         // code exchange itself (qcHandoff / qcCodeArrived / qcExchangeScript). Hints travel through huoyingair-note:.
         return "(function(){if(window.__airPcLogin)return;window.__airPcLogin=1;" + "var graph='https://graph.qq.com',sent=0,noted={};" + "function note(t){if(noted[t])return;noted[t]=1;try{location.href='huoyingair-note:'+encodeURIComponent(t);}catch(e){}}" + "function scan(doc,acc){var list=doc.querySelectorAll('iframe');for(var i=0;i<list.length;i++){var f=list[i];acc.push(f);try{var d=f.contentDocument;if(d&&d.querySelectorAll)scan(d,acc);}catch(e){}}return acc;}" + "function fix(){if(sent||window.__airQcBusy)return;var frames=scan(document,[]);" + "for(var i=0;i<frames.length;i++){var f=frames[i],u;" + "try{u=new URL(f.getAttribute('src')||'',location.href);}catch(e){continue;}" + "if(u.origin===graph&&(u.pathname==='/oauth2.0/authorize'||u.pathname==='/oauth2.0/show')){sent=1;try{f.src='about:blank';}catch(e){}location.href='huoyingair-qc:'+encodeURIComponent(u.href);return;}" + "if(u.hostname==='xui.ptlogin2.qq.com'&&u.searchParams.get('appid')==='21000501'){sent=1;try{f.src='about:blank';}catch(e){}location.href='huoyingair-qc:plain';return;}}}" + "setInterval(fix,300);" + "setTimeout(function(){var un=document.getElementById('unlogin');if(!sent&&un&&un.offsetParent!==null)note('\\u767b\\u5f55\\u6846\\u6ca1\\u6709\\u81ea\\u52a8\\u5f39\\u51fa\\u65f6\\uff0c\\u8bf7\\u70b9\\u9875\\u9762\\u53f3\\u4e0a\\u89d2\\u7684\\u300c\\u767b\\u5f55\\u300d');},15000);})()";
      }
      
      private function qcExchangeScript(param1:String) : String
      {
         // Mirrors milo LoginManager.qcLogin's qqConnectCallback: swap the OAuth code for openid/access_token at AMS, write
         // the same four cookies milo writes, then let milo's checkLogin establish IED_LOG_INFO2_QC before reloading.
         return "(function(code,appid,redirect){window.__airQcBusy=1;" + "function note(t){try{location.href='huoyingair-note:'+encodeURIComponent(t);}catch(e){}}" + "function cookie(n,v,e){try{milo.cookie.set(n,v,e,location.host,'/');}catch(x){document.cookie=n+'='+v+';path=/;domain='+location.host+';max-age='+e;}}" + "var done=0;function go(){if(done)return;done=1;location.reload();}" + "window.__airQcDone=function(r){if(!r||r.iRet!=0){window.__airQcBusy=0;note('\\u6362\\u7968\\u5931\\u8d25 '+(r&&r.sMsg?String(r.sMsg).substr(0,30):'')+'\\uff0c\\u8bf7\\u91cd\\u65b0\\u767b\\u5f55');return;}" + "var e=r.expires_in||86400;cookie('openid',r.openid,e);cookie('access_token',r.access_token,e);cookie('appid',appid,e);cookie('acctype','qc',e);" + "note('\\u767b\\u5f55\\u6210\\u529f\\uff0c\\u6b63\\u5728\\u6821\\u9a8c\\u767b\\u5f55\\u6001');" + "try{need('biz.login',function(LM){LM.checkLogin(function(){go();},function(){window.__airQcBusy=0;note('\\u767b\\u5f55\\u6001\\u6821\\u9a8c\\u672a\\u901a\\u8fc7\\uff0c\\u8bf7\\u91cd\\u65b0\\u767b\\u5f55');});});}catch(x){go();}" + "setTimeout(go,8000);};" + "var s=document.createElement('script');s.onerror=function(){window.__airQcBusy=0;note('\\u6362\\u7968\\u8bf7\\u6c42\\u5931\\u8d25\\uff0c\\u8bf7\\u68c0\\u67e5\\u7f51\\u7edc\\u540e\\u91cd\\u65b0\\u767b\\u5f55');};" + "s.src='https://ams.game.qq.com/ams/userLoginSvr?a=qcCodeToOpenId&qc_code='+encodeURIComponent(code)+'&appid='+encodeURIComponent(appid)+'&redirect_uri='+encodeURIComponent(redirect)+'&callback=__airQcDone&_='+Date.now();" + "document.head.appendChild(s);})(" + JSON.stringify(param1) + "," + JSON.stringify(this.qcAppId || "102045649") + "," + JSON.stringify(this.qcRedirect || "https://huoying.qq.com/comm-htdocs/login/qc_redirect.html") + ")";
      }
      
      private function queryParam(param1:String, param2:String) : String
      {
         var found:Array = new RegExp("[?&]" + param2 + "=([^&#]*)").exec(param1);
         if(!found)
         {
            return "";
         }
         try
         {
            return decodeURIComponent(String(found[1]));
         }
         catch(err:Error)
         {
         }
         return "";
      }
      
      private function qcHandoff(param1:String) : void
      {
         var auth:String = "";
         var now:Number = new Date().time;
         if(!this.browser || Boolean(this.started) || now - this.qcHandoffTime < 4000)
         {
            return;
         }
         this.qcHandoffTime = now;
         try
         {
            auth = decodeURIComponent(param1.substr("huoyingair-qc:".length));
         }
         catch(err:Error)
         {
            auth = "";
         }
         var clientId:String = this.queryParam(auth,"client_id") || "102045649";
         var redirect:String = this.queryParam(auth,"redirect_uri") || "https://huoying.qq.com/comm-htdocs/login/qc_redirect.html?parent_domain=https%3A%2F%2Fhuoying.qq.com";
         var state:String = this.queryParam(auth,"state") || "STATE";
         var scope:String = this.queryParam(auth,"scope") || "get_user_info";
         this.qcAppId = clientId;
         this.qcState = state;
         this.qcRedirect = redirect.split("?")[0];
         this.record("QQ 互联改走整页电脑版登录 " + auth.replace(/[?#].*$/,"").substr(0,60));
         this.report("已打开电脑版 QQ 登录页：点「密码登录」输入账号密码，登录后点「授权」");
         this.browser.loadURL("https://graph.qq.com/oauth2.0/show?which=Login&display=pc&response_type=code&client_id=" + encodeURIComponent(clientId) + "&redirect_uri=" + encodeURIComponent(redirect) + "&state=" + encodeURIComponent(state) + "&scope=" + encodeURIComponent(scope));
      }
      
      private function qcCodeArrived(param1:String) : void
      {
         var code:String = this.queryParam(param1,"code");
         var state:String = this.queryParam(param1,"state");
         if(!code || !this.browser || Boolean(this.started))
         {
            return;
         }
         if(Boolean(this.qcState) && state != this.qcState)
         {
            this.report("登录来源校验失败，请重新登录");
            this.browser.loadURL("https://huoying.qq.com/server/website/");
            return;
         }
         this.pendingQcCode = code;
         this.record("QQ 互联授权码已拦截");
         this.report("授权成功，正在换取登录票据…");
         this.browser.loadURL("https://huoying.qq.com/server/website/");
      }
      
      private function sessionCapture(param1:String, param2:Boolean) : String
      {
         return "(function(probe,micro){" + "if(location.origin!==\'https://game.huoying.qq.com\'||!window.web||typeof web.getUin!==\'function\')return;" + "var entry=document.getElementById(\'entry\'),src,vars;" + "if(entry){src=entry.src||entry.getAttribute(\'src\')||entry.getAttribute(\'data\');vars=entry.getAttribute(\'flashvars\');" + "Array.prototype.forEach.call(entry.querySelectorAll(\'param\'),function(param){" + "var name=String(param.name).toLowerCase();if(name===\'movie\'&&!src)src=param.value;if(name===\'flashvars\'&&!vars)vars=param.value;});}" + "if((probe||micro)&&!src&&typeof web.getEntrySwfUrl===\'function\')src=web.getEntrySwfUrl();" + "if(!src)return;var url=new URL(src,document.baseURI||location.href);" + "if((probe||micro)&&(!/^https?:$/.test(url.protocol)||url.hostname!==\'res.huoying.qq.com\'||url.port||url.username||url.password||url.hash||!/^\\/NarutoBeta[0-9.]+Build[0-9]+\\/entry\\.swf$/.test(url.pathname)))return;" + "var cookies=Object.create(null),parameters=Object.create(null),page=Object.create(null);" + "document.cookie.split(\';\').forEach(function(part){var i=part.indexOf(\'=\');if(i<0)return;" + "var key=part.slice(0,i).trim();if(key)cookies[key]=typeof getCookie===\'function\'?getCookie(key):part.slice(i+1);});" + "if(!cookies.access_token||!cookies.openid)return;" + "url.searchParams.forEach(function(value,key){parameters[key]=value;});" + "if(vars)new URLSearchParams(vars).forEach(function(value,key){parameters[key]=value;});" + "new URL(location.href).searchParams.forEach(function(value,key){page[key]=value;});" + "var account=micro&&/^\\d{5,20}$/.test(cookies.fake_id)?cookies.fake_id:String(web.getUin()).trim();" + "var data={account:account,entryURL:url.href,parameters:parameters,pageParameters:page,cookies:cookies,userAgent:navigator.userAgent};" + "if(probe)data.probe=probe;" + "return \'huoyingair-session:\'+encodeURIComponent(JSON.stringify(data));})(" + JSON
         .stringify(param1) + "," + param2 + ")";
      }
      
      private function microFrameCapture() : String
      {
         return "(function(){if(!window.airMicroSession)return;" + "if(window===window.top){" + "if(location.href!==\'https://minigame.qq.com/plat/social_hall/app_frame/index_v4.html?appid=1103286479\')return;" + "function launch(){var frame=document.getElementById(\'iframe_app\');if(!frame||!frame.getAttribute(\'src\'))return;" + "var url=new URL(frame.src,location.href);if((url.protocol!==\'https:\'&&url.protocol!==\'http:\')||![\'huoying.qq.com\',\'game.huoying.qq.com\'].includes(url.hostname))return;" + "observer.disconnect();window.airMicroSession.postMessage(\'launch:\'+url.href);}" + "var observer=new MutationObserver(launch);observer.observe(document,{childList:true,subtree:true,attributes:true,attributeFilter:[\'src\']});launch();return;}" + "var deadline=Date.now()+180000;var timer=setInterval(function(){" + "if(Date.now()>deadline){clearInterval(timer);return;}" + "var packet=" + this.sessionCapture(null,true) + ";" + "if(packet){clearInterval(timer);window.airMicroSession.postMessage(packet);}},500);})()";
      }
      
      private function locationChanging(param1:Event) : void
      {
         var _loc2_:String = Object(param1).location;
         if(_loc2_.indexOf("wtloginmqq:") == 0)
         {
            param1.preventDefault();
            if(Boolean(this.qq))
            {
               this.qq.call("open",_loc2_);
            }
            else
            {
               this.report(this.iosTest ? "iOS 不支持调起手机 QQ，请在登录框点「密码登录」" : "手机 QQ 登录组件尚未就绪");
            }
            return;
         }
         if(_loc2_.indexOf("huoyingair-control:") == 0)
         {
            param1.preventDefault();
            this.control(_loc2_);
            return;
         }
         if(_loc2_.indexOf("huoyingair-note:") == 0)
         {
            param1.preventDefault();
            this.webNote(_loc2_);
            return;
         }
         if(_loc2_.indexOf("huoyingair-qc:") == 0)
         {
            param1.preventDefault();
            this.qcHandoff(_loc2_);
            return;
         }
         if(Boolean(this.iosTest) && /^https:\/\/huoying\.qq\.com\/comm-htdocs\/login\/(qc_redirect|qccallback)\.html\?/.test(_loc2_) && Boolean(this.queryParam(_loc2_,"code")))
         {
            param1.preventDefault();
            this.qcCodeArrived(_loc2_);
            return;
         }
         if(Boolean(this.iosTest) && !this.started && /^https?:/.test(_loc2_))
         {
            this.record("页面跳转 " + _loc2_.replace(/[?#].*$/,"").substr(0,100) + (this.queryParam(_loc2_,"style") ? " style=" + this.queryParam(_loc2_,"style") : "") + (this.queryParam(_loc2_,"appid") ? " appid=" + this.queryParam(_loc2_,"appid") : ""));
         }
         if(_loc2_.indexOf("huoyingair-session:") != 0)
         {
            return;
         }
         param1.preventDefault();
         this.acceptSession(_loc2_);
      }
      
      private function acceptSession(param1:String, param2:Boolean = false) : void
      {
         var phase:String = null;
         var bridge:Object = null;
         var d:Object = null;
         var Type:Class = null;
         var gameAgent:Object = null;
         var url:String = param1;
         var nativeOrigin:Boolean = param2;
         if(Boolean(this.started) || (nativeOrigin ? !this.qqReady : !this.trusted))
         {
            return;
         }
         if(Boolean(this.iosTest) && (!this.sessionProbe || url.length > 131072 || !/^https:\/\/game\.huoying\.qq\.com\//.test(this.browser.location)))
         {
            return;
         }
         phase = "会话格式";
         try
         {
            d = JSON.parse(decodeURIComponent(url.substr("huoyingair-session:".length)));
            if(Boolean(this.iosTest) && d.probe !== this.sessionProbe)
            {
               return;
            }
            d.entryURL = String(d.entryURL).replace(/^http:\/\/res\.huoying\.qq\.com\//,"https://res.huoying.qq.com/");
            phase = "QQ 账号格式";
            if(!/^\d{5,20}$/.test(d.account))
            {
               throw new Error("account");
            }
            phase = "官方入口地址";
            Object(getDefinitionByName("airgame.bridge.OfficialResources")).select(d.entryURL);
            phase = "区服编号";
            if(!d.parameters || !/^\d{1,6}$/.test(String(d.parameters.zone_id)))
            {
               throw new Error("zone");
            }
            phase = "区服服务器地址";
            if(String(d.parameters.ip).toLowerCase().replace(/\.$/,"") != "zone.huoying.qq.com")
            {
               throw new Error("host");
            }
            phase = "QQ 登录凭据";
            if(!d.cookies || !d.cookies.access_token || !d.cookies.openid)
            {
               throw new Error("cookies");
            }
            phase = "微端授权渠道";
            if(Boolean(this.microLogin) && String(d.cookies.appid) != "1103286479")
            {
               throw new Error("micro_appid");
            }
            phase = "启动游戏容器";
            this.record("官方入口版本 " + String(d.entryURL).split("/")[3]);
            if(this.qqReady)
            {
               gameAgent = this.qq.call("gameUserAgent");
               if(Boolean(gameAgent))
               {
                  d.userAgent = String(gameAgent);
               }
            }
            if(!this.iosTest)
            {
               this.nativeApp.executeInBackground = true;
               this.record("后台执行 enabled");
               if(!this.microLogin)
               {
                  this.browser.loadURL("javascript:window.airControlKey=" + JSON.stringify(this.bridgeKey) + ";void(0)");
               }
            }
            this.session = d;
            this.session.returns = {};
            this.started = true;
            this.browser.stage = null;
            if(Boolean(this.navBar))
            {
               this.navBar.visible = false;
            }
            bridge = getDefinitionByName("airgame.bridge.ExternalInterface");
            bridge.settings = d;
            bridge.notify = this.external;
            Type = getDefinitionByName("airgame.bridge.Loader") as Class;
            this.loader = new Type() as flash.display.Loader;
            this.loader.contentLoaderInfo.addEventListener("ioError",function(param1:Event):void
            {
               report("游戏入口下载失败，请退出后重试");
            });
            if(this.iosTest)
            {
               this.loader.contentLoaderInfo.addEventListener("securityError",function(param1:Event):void
               {
                  report("iOS 游戏入口加载受限 #" + Object(param1).errorID);
               });
            }
            this.loader.contentLoaderInfo.addEventListener(Event.INIT,function(param1:Event):void
            {
               report("入口初始化 " + loader.contentLoaderInfo.loaderURL.split("?")[0]);
            });
            this.loader.contentLoaderInfo.addEventListener(Event.COMPLETE,function(param1:Event):void
            {
               stage.scaleMode = "noScale";
               stage.dispatchEvent(new Event(Event.RESIZE));
               report("火影OL · 区服 " + d.parameters.zone_id);
               report("入口容器 " + loader.content.loaderInfo.loaderURL.split("?")[0]);
            });
            addChildAt(this.loader,0);
            this.report("正在下载游戏资源，请稍候…");
            this.downloading = new flash.net.URLLoader();
            this.downloading.dataFormat = URLLoaderDataFormat.BINARY;
            this.downloading.addEventListener("ioError",function(param1:Event):void
            {
               loginIssue("官方资源下载失败，可重启当前账号后重试",true);
            });
            this.downloading.addEventListener(Event.COMPLETE,function(param1:Event):void
            {
               var Context:Class;
               var context:Object;
               var entryBytes:ByteArray = null;
               var ev:Event = param1;
               var domain:ApplicationDomain = new ApplicationDomain(ApplicationDomain.currentDomain);
               Object(getDefinitionByName("airgame.bridge.RuntimeAdapter")).gameDomain = domain;
               Context = getDefinitionByName("airgame.bridge.LoaderContext") as Class;
               context = new Context(false,domain);
               context.parameters = d.parameters;
               try
               {
                  entryBytes = Object(getDefinitionByName("airgame.bridge.RuntimeAdapter")).apply(downloading.data as ByteArray,true);
                  loader.loadBytes(entryBytes,context as flash.system.LoaderContext);
               }
               catch(adaptError:Error)
               {
                  loginIssue("入口兼容适配失败，请点 ⋮ → 分享日志");
               }
            });
            this.downloading.load(new URLRequest(String(d.entryURL).split("?")[0]));
            if(this.qqReady)
            {
               this.qq.call("gameStarted");
            }
         }
         catch(err:Error)
         {
            if(started)
            {
               if(Boolean(downloading))
               {
                  try
                  {
                     downloading.close();
                  }
                  catch(closeError:Error)
                  {
                  }
               }
               if(Boolean(loader) && loader.parent === this)
               {
                  removeChild(loader);
               }
               if(Boolean(bridge))
               {
                  bridge.settings = null;
               }
               session = null;
               started = false;
               browser.stage = stage;
               layout();
            }
            sessionWaitHint = true;
            if(sessionFailure != phase)
            {
               sessionFailure = phase;
               loginIssue("登录失败 · " + phase + "。可重载选区或点 ⋮ → 分享日志");
               record("登录衔接失败 " + phase + " " + err.name + " #" + err.errorID);
            }
         }
      }
      
      private function control(param1:String) : void
      {
         var request:Object = null;
         var result:Object = null;
         var url:String = param1;
         if(this.iosTest)
         {
            return;
         }
         if(++this.controlReceived <= 200)
         {
            this.record("控制收到 " + this.controlReceived + " started=" + this.started + " trusted=" + this.trusted + " native=" + this.qqReady);
         }
         if(!this.started || !this.qqReady && !this.trusted)
         {
            return;
         }
         try
         {
            request = JSON.parse(decodeURIComponent(url.substr("huoyingair-control:".length)));
            if(request.key !== this.bridgeKey)
            {
               return;
            }
            try
            {
               result = {
                  "seq":request.seq,
                  "ok":true,
                  "value":Object(getDefinitionByName("airgame.bridge.GameBridge")).execute(stage,request.command)
               };
            }
            catch(error:Error)
            {
               result = {
                  "seq":request.seq,
                  "ok":false,
                  "error":error.name + ":" + error.errorID
               };
            }
            if(this.qqReady)
            {
               this.qq.call("controlReply",JSON.stringify(result));
            }
            else
            {
               this.browser.loadURL("javascript:window.airControlResult=" + JSON.stringify(result) + ";void(0)");
            }
         }
         catch(error:Error)
         {
         }
      }
      
      private function applySpeed() : void
      {
         try
         {
            Object(getDefinitionByName("airgame.bridge.SpeedClock")).setSpeed(this.desiredSpeed);
            if(this.gameReady)
            {
               stage.frameRate = 30 * this.desiredSpeed;
            }
         }
         catch(error:Error)
         {
            desiredSpeed = 1;
            report("倍速设置失败，已保留原速");
         }
      }
      
      private function external(param1:Object) : void
      {
         var _loc4_:String = null;
         if(!this.browser || !this.qqReady && !this.trusted)
         {
            return;
         }
         if(Boolean(this.iosTest) && !/^https:\/\/game\.huoying\.qq\.com\//.test(this.browser.location))
         {
            return;
         }
         var _loc3_:String = param1.method;
         if(!/^[A-Za-z_$][A-Za-z0-9_$.]{0,120}$/.test(_loc3_) || _loc3_ == "open" || _loc3_ == "window.open" || _loc3_ == "location.reload")
         {
            return;
         }
         try
         {
            _loc4_ = "(function(){var n=" + JSON.stringify(_loc3_) + ",a=" + JSON.stringify(param1.arguments) + ",o=window,p=n.split(\'.\');if(p[0]===\'window\')p.shift();var k=p.pop();for(var i=0;i<p.length;i++){o=o&&o[p[i]];if(!o)return;}if(o&&typeof o[k]===\'function\')o[k].apply(o,a);})()";
            if(this.qqReady)
            {
               this.qq.call("gameScript",_loc4_);
            }
            else
            {
               this.browser.loadURL("javascript:" + _loc4_);
            }
         }
         catch(err:Error)
         {
         }
      }
   }
}

