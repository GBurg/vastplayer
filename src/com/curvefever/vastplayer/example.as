package com.curvefever.vastplayer {
  import flash.system.Security;
  import flash.text.TextField;
  import flash.display.MovieClip;
  /**
   * @author Geert
   */
  public class example extends MovieClip {
    
    var txt:TextField = new TextField();
    
    
    public function example() {
      
      Security.allowDomain("curvefever.com");
      Security.allowDomain("ads.curvefever.com");
      
      stage.color = 0x000000;
			txt.height = 768;
      txt.width = 200;
      txt.textColor = 0xffffff;   
       addChild(txt);
      
      var player:VASTplayer = new VASTplayer();
      TestUtils.enableLogging("http://dev.achtungdiekurve.net/code/log.php", txt);
     	// CF 2 preroll
      //player.init("http://ads.curvefever.com/www/delivery/fc.php?script=apVideo:vast2&zoneid=3");
      // CF 1 preroll
      //player.init("http://ads.curvefever.com/www/delivery/fc.php?script=apVideo:vast2&zoneid=4");
      // CF testzone
      player.init("http://ads.curvefever.com/www/delivery/fc.php?script=apVideo:vast2&zoneid=5");
      
      // demo
      //player.init("http://www.adotube.com/kernel/vast/vast.php?omlSource=http://www.adotube.com/php/services/player/OMLService.php?avpid=UDKjuff&ad_type=pre-rolls&platform_version=vast20as3&vpaid=1&rtb=0&publisher=adotube.com&title=[VIDEO_TITLE]&tags=[VIDEO_TAGS]&description=[VIDEO_DESCRIPTION]&videoURL=[VIDEO_FILE_URL]&http_ref=[HTTP_REFERRER]");
      
      // live
      //player.init("http://www.adotube.com/kernel/vast/vast.php?omlSource=http://www.adotube.com/php/services/player/OMLService.php?avpid=4WGV9QE&ad_type=pre-rolls&vpaid=1&rtb=0&platform_version=vast20as3&publisher=&title=&tags=&description=&videoURL=&http_ref=");
      
      player.play(); 
      
      addChild(player);
      
      
      
      /*var textLoader:URLLoader = new URLLoader();
			var textReq:URLRequest = new URLRequest("http://curvefever.com/code/client_refer.php");
			textLoader.load(textReq);
			textLoader.addEventListener(Event.COMPLETE, function(e:Event) {
        trace(textLoader.data);
      });
      
      var url:String = loaderInfo.loaderURL;
      trace("url:"+url);*/
      
    }
  }
}
