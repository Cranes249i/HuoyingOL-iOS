package airgame.bridge
{
   import flash.utils.*;
   
   public class SpeedClock
   {
      
      public static var multiplier:Number = 1;
      
      public static var timers:Dictionary = new Dictionary(true);
      
      private static var realAnchor:int = flash.utils.getTimer();
      
      private static var virtualAnchor:Number = realAnchor;
      
      public function SpeedClock()
      {
         super();
      }
      
      public static function now() : int
      {
         return int(virtualAnchor + uint(flash.utils.getTimer() - realAnchor) * multiplier);
      }
      
      public static function setSpeed(param1:Number) : void
      {
         var _loc2_:Object = null;
         if(param1 != 0.5 && param1 != 1 && param1 != 2 && param1 != 3 && param1 != 5)
         {
            throw new ArgumentError("unsupported_speed");
         }
         virtualAnchor = now();
         realAnchor = flash.utils.getTimer();
         multiplier = param1;
         for(_loc2_ in timers)
         {
            _loc2_.rescale();
         }
      }
   }
}

