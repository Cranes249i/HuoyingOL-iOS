package
{
   import flash.display.Shape;
   import flash.display.Sprite;

   /** Tiny SWF with ActionScript; loaded via Loader.loadBytes by IosProbe. */
   public class Probe2 extends Sprite
   {
      public var constructed:Boolean = false;

      public function Probe2()
      {
         super();
         constructed = true;
         var s:Shape = new Shape();
         s.graphics.beginFill(0x00CC66);
         s.graphics.drawCircle(40, 40, 30);
         s.graphics.endFill();
         addChild(s);
         trace("[PROBE2] constructed");
      }

      public function ping(n:int):int
      {
         var total:int = 0;
         for(var i:int = 0; i < n; i++) total += 2;
         return total;
      }
   }
}
