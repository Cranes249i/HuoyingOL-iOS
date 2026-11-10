package airgame.bridge
{
   import flash.utils.Timer;
   
   public class Timer extends flash.utils.Timer
   {
      
      private var originalDelay:Number;
      
      public function Timer(param1:Number, param2:int = 0)
      {
         super(param1 / SpeedClock.multiplier,param2);
         this.originalDelay = param1;
         SpeedClock.timers[this] = true;
      }
      
      override public function get delay() : Number
      {
         return this.originalDelay;
      }
      
      override public function set delay(param1:Number) : void
      {
         super.delay = param1 / SpeedClock.multiplier;
         this.originalDelay = param1;
      }
      
      public function rescale() : void
      {
         super.delay = this.originalDelay / SpeedClock.multiplier;
      }
   }
}

