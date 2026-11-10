package airgame.bridge
{
   import flash.utils.*;
   
   public class Security
   {
      
      private static var implementation:Object = getDefinitionByName("flash.system.Security");
      
      public static const APPLICATION:String = "application";
      
      public static const REMOTE:String = "remote";
      
      public static const LOCAL_TRUSTED:String = "localTrusted";
      
      public static const LOCAL_WITH_FILE:String = "localWithFile";
      
      public static const LOCAL_WITH_NETWORK:String = "localWithNetwork";
      
      public function Security()
      {
         super();
      }
      
      public static function get sandboxType() : String
      {
         return implementation.sandboxType;
      }
      
      public static function allowDomain(... rest) : void
      {
         if(sandboxType != APPLICATION)
         {
            implementation.allowDomain.apply(null,rest);
         }
      }
      
      public static function allowInsecureDomain(... rest) : void
      {
         if(sandboxType != APPLICATION)
         {
            implementation.allowInsecureDomain.apply(null,rest);
         }
      }
      
      public static function loadPolicyFile(param1:String) : void
      {
         if(sandboxType != APPLICATION)
         {
            implementation.loadPolicyFile(param1);
         }
      }
      
      public static function get exactSettings() : Boolean
      {
         return implementation.exactSettings;
      }
      
      public static function set exactSettings(param1:Boolean) : void
      {
         if(sandboxType != APPLICATION)
         {
            implementation.exactSettings = param1;
         }
      }
      
      public static function showSettings(param1:String = "default") : void
      {
         implementation.showSettings(param1);
      }
   }
}

