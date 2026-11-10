package airgame.bridge
{
   import flash.events.*;
   import flash.net.Socket;
   
   public class Socket extends flash.net.Socket
   {
      
      public static var diagnostics:Array = [];
      
      private var target:String;
      
      private var targetPort:int;
      
      public function Socket(param1:String = null, param2:int = 0)
      {
         var _loc3_:String = null;
         super();
         for each(_loc3_ in [Event.CONNECT,Event.CLOSE,IOErrorEvent.IO_ERROR,SecurityErrorEvent.SECURITY_ERROR])
         {
            addEventListener(_loc3_,this.observed,false,10000);
         }
         if(param1 != null)
         {
            this.connect(param1,param2);
         }
      }
      
      private function record(param1:String, param2:int = 0) : void
      {
         diagnostics.push({
            "kind":param1,
            "host":this.target,
            "port":this.targetPort,
            "errorID":param2
         });
         if(diagnostics.length > 40)
         {
            diagnostics.shift();
         }
      }
      
      private function observed(param1:Event) : void
      {
         this.record(param1.type,param1 is IOErrorEvent ? int(IOErrorEvent(param1).errorID) : (param1 is SecurityErrorEvent ? int(SecurityErrorEvent(param1).errorID) : 0));
      }
      
      override public function connect(param1:String, param2:int) : void
      {
         var host:String = param1;
         var port:int = param2;
         this.target = host;
         this.targetPort = port;
         this.record("connectRequested");
         try
         {
            super.connect(host,port);
         }
         catch(error:Error)
         {
            record(error.name,error.errorID);
            throw error;
         }
      }
   }
}

