package com.curvefever.vastplayer {
  import flash.text.TextField;
  import flash.net.URLLoader;
  import flash.net.URLRequestMethod;
  import flash.net.URLRequest;
  import flash.net.URLVariables;
  /**
   * @author Geert
   */
  public class TestUtils {
    
    private static var counter:int = 0;
    private static var url:String = "";
    private static var txt:TextField;
    
    
    public static function deepTrace(obj:Object, lvl:int = 0):void {
			var tabs:String = "";
			for (var i:int = 0; i < lvl; i++ )
				tabs += "\t";
			for (var k:String in obj) {
				trace(tabs + "[" + k + "]: " + obj[k]);
				if (obj[k] is Object)
					deepTrace(obj[k], lvl + 1);
			}
		}
    
    public static function enableLogging(url:String, txt:TextField = null):void {
      TestUtils.url = url;
      TestUtils.txt = txt;
    }
    
    public static function log(m:String):void {
    	if (url != "") {  
	      var variables:URLVariables = new URLVariables();
	      variables.m = (counter++)+""+m;
        trace(variables.m);
        if (txt != null) txt.appendText(variables.m+"\n");
	      var request:URLRequest = new URLRequest(url);
	      request.data = variables;
				request.method = URLRequestMethod.POST;
	      var loader:URLLoader = new URLLoader();
	      loader.load(request);
      }
       
    }
    
  }
}
