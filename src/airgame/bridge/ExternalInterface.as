package airgame.bridge
{
   public class ExternalInterface
   {
      
      public static var settings:Object;
      
      public static var notify:Function;
      
      public static var callbacks:Object = {};
      
      public static var calls:Object = {};
      
      public static var marshallExceptions:Boolean = false;
      
      public function ExternalInterface()
      {
         super();
      }
      
      public static function get available() : Boolean
      {
         return settings != null;
      }
      
      public static function get objectID() : String
      {
         return "entry";
      }
      
      public static function addCallback(param1:String, param2:Function) : void
      {
         callbacks[param1] = param2;
      }
      
      public static function call(param1:String, ... rest) : *
      {
         calls[param1] = (calls[param1] || 0) + 1;
         if(param1 == "getUin")
         {
            return settings.account;
         }
         if(param1 == "getCookie")
         {
            return settings.cookies[String(rest[0])] || "";
         }
         if(param1 == "getUrlParam")
         {
            return settings.pageParameters[String(rest[0])] || null;
         }
         if(param1 == "window.navigator.userAgent.toLowerCase")
         {
            return String(settings.userAgent).toLowerCase();
         }
         if(Boolean(settings.returns) && param1 in settings.returns)
         {
            return settings.returns[param1];
         }
         if(notify != null)
         {
            notify({
               "event":"external",
               "method":param1,
               "arguments":rest
            });
         }
         return null;
      }
   }
}

