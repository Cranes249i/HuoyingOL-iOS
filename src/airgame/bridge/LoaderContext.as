package airgame.bridge
{
   import flash.system.ApplicationDomain;
   import flash.system.LoaderContext;
   import flash.system.SecurityDomain;
   
   public class LoaderContext extends flash.system.LoaderContext
   {
      
      public function LoaderContext(param1:Boolean = false, param2:ApplicationDomain = null, param3:SecurityDomain = null)
      {
         super(param1,param2,param3);
         if("allowCodeImport" in this)
         {
            Object(this).allowCodeImport = true;
         }
         if("allowLoadBytesCodeExecution" in this)
         {
            Object(this).allowLoadBytesCodeExecution = true;
         }
      }
   }
}

