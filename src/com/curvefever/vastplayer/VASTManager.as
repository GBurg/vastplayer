package com.curvefever.vastplayer {
  import com.hinish.examples.vast.extensions.parsers.DARTInfoParser;
  import com.hinish.examples.vast.extensions.parsers.PreviousAdInformationParser;
  import com.hinish.spec.iab.vast.parsers.VASTParser;
  import com.hinish.spec.iab.vast.vos.Ad;
  import com.hinish.spec.iab.vast.vos.Creative;
  import com.hinish.spec.iab.vast.vos.MediaFile;
  import com.hinish.spec.iab.vast.vos.TrackingEvent;
  import com.hinish.spec.iab.vast.vos.URIIdentifier;
  import com.hinish.spec.iab.vast.vos.VAST;
  import com.hinish.spec.iab.vast.vos.Wrapper;
  import com.hinish.spec.xs.Time;

  import flash.events.Event;
  import flash.events.EventDispatcher;
  import flash.events.IOErrorEvent;
  import flash.events.ProgressEvent;
  import flash.events.SecurityErrorEvent;
  import flash.net.URLLoader;
  import flash.net.URLRequest;
  /**
   * @author Geert
   */
  [Event(name="vm_LOADED", type="com.curvefever.vastplayer.VASTManager")]
  [Event(name="vm_NOADS", type="com.curvefever.vastplayer.VASTManager")]
  [Event(name="vm_ERROR", type="com.curvefever.vastplayer.VASTManager")]
  public class VASTManager extends EventDispatcher {
    
    public static const LOADED:String = "vm_LOADED";
    public static const NOADS:String = "vm_NOADS";
    public static const ERROR:String = "vm_ERROR";
    
    private var _url:String;
    private var _vmaxd:int;
    private var _vpl:String;
    private var _parent:VASTManager;
    private var _child:VASTManager;
    
    private var _vastParser:VASTParser;
    private var _vastUrlRequest:URLRequest;
    private var _vastUrlLoader:URLLoader;
    private var _vastXML:XML;
    private var _vastOutput:VAST;
    
    
    
    
    
    public function VASTManager() {
      _vastParser = new VASTParser();
      _vastParser.registerExtensionParser(new PreviousAdInformationParser());
			_vastParser.registerExtensionParser(new DARTInfoParser());
      
      _vastUrlLoader = new URLLoader();
      _vastUrlLoader.addEventListener(ProgressEvent.PROGRESS, onUrlProgressAction);
      _vastUrlLoader.addEventListener(Event.COMPLETE, onUrlLoadedAction);
      _vastUrlLoader.addEventListener(IOErrorEvent.IO_ERROR, onUrlErrorAction);
      _vastUrlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
    }
    
    public function init(url:String, parent:VASTManager = null, Vmaxd:int = 30, VPl:String = "FLV"):void {
      _url = url;
      _parent = parent;
      _vmaxd = Vmaxd;
      _vpl = VPl;
    }
    
    public function load():void {
      TestUtils.log("manager - load");
      _vastUrlRequest = new URLRequest(_url+"&VMaxd="+_vmaxd+"&VPl="+_vpl+"&random="+Math.floor(Math.random()*int.MAX_VALUE));
      TestUtils.log("manager - load: urlrequest "+_url+"&VMaxd="+_vmaxd+"&VPl="+_vpl+"&random="+Math.floor(Math.random()*int.MAX_VALUE));
      try {
      	_vastUrlLoader.load(_vastUrlRequest);
      } catch (e:Error) {
        onUrlLoadError(e);
      }
    }
    private function onUrlLoadError(e:Error):void {
      TestUtils.log("manager - onUrlLoadError - "+e);
      if (_parent == null){
      	trace(e.toString());
        dispatchEvent(new Event(VASTManager.ERROR));
      } else {
        _parent.onUrlLoadError(e);
      }
    }
    private function onSecurityError(e:SecurityErrorEvent):void {
      TestUtils.log("manager - onSecurityError - "+e);
      if (_parent == null){
      	trace(e.toString());
        dispatchEvent(new Event(VASTManager.ERROR));
        //dispatchEvent(new SecurityErrorEvent(e.type,e.bubbles,e.cancelable,e.text));
      } else {
        _parent.onSecurityError(e);
      }
    }
    private function onUrlProgressAction(e:ProgressEvent):void {
      TestUtils.log("manager - onUrlProgressAction - "+(e.bytesLoaded/e.bytesTotal*100));
      trace(e.bytesLoaded/e.bytesTotal*100);
    }
    private function onUrlErrorAction(e:IOErrorEvent):void {
      TestUtils.log("manager - onUrlErrorAction - "+e.toString());
      if (_parent == null){
      	trace(e.toString());
        dispatchEvent(new Event(VASTManager.ERROR));
        //dispatchEvent(new IOErrorEvent(e.type,e.bubbles,e.cancelable,e.text));
      } else {
        _parent.onUrlErrorAction(e);
      }
    }
    private function onUrlLoadedAction(e:Event):void {
      TestUtils.log("manager - onUrlLoadedAction: "+e.target.data);
      _vastXML = XML(e.target.data);
      _vastParser.setData(_vastXML);
      _vastOutput = _vastParser.parse();
      
      // now we need to see if we need a deeper nesting of our vast player
      if (_vastOutput.ads.length == 0) {
      	// there are no ads, so skip this thing
      	noAds();
      } else if (isWrapper()) {
        _child = new VASTManager();
        _child.init(Wrapper(_vastOutput.ads[0]).vastAdTagURI,this, _vmaxd, _vpl);
        _child.load();
      } else {
        loaded();
      }
    }
    private function noAds():void {
      if (_parent == null) dispatchEvent(new Event(VASTManager.NOADS));
      else _parent.noAds();
    }
    private function loaded():void {
      if (_parent == null) dispatchEvent(new Event(VASTManager.LOADED));
      else _parent.loaded();
    }
    private function isWrapper():Boolean {
      
      TestUtils.log("VASTManager - isWrappper: "+_vastOutput);
      
      return (_vastOutput.ads[0] is Wrapper);
    }
    
    
    public function getDuration(adId:int, creativeId:int):Time {
      if (_child == null) return _vastOutput.ads[adId].creatives[creativeId].source.duration;
      else return _child.getDuration(adId, creativeId);
    }
    
    public function getAd(adId:int):Ad {
      if (_child == null) return _vastOutput.ads[adId];
      else return _child.getAd(adId);
    }
    public function getCreative(adId:int, creativeId:int):Creative {
      if (_child == null) return _vastOutput.ads[adId].creatives[creativeId];
      else return _child.getCreative(adId, creativeId);
    }
    public function getMediaFile(adId:int, creativeId:int):MediaFile {
      if (_child == null) return _vastOutput.ads[adId].creatives[creativeId].source.mediaFiles[0];
      else return _child.getMediaFile(adId, creativeId);
    }
    public function getClickThroughUrl(adId:int, creativeId:int):String  {
      if (_child == null) {
        var creative:Creative = _vastOutput.ads[adId].creatives[creativeId];
        return creative.source.videoClicks.clickThrough.uri;
      }
      else return _child.getClickThroughUrl(adId, creativeId);
    }
    public function getMediaUrl(adId:int, creativeId:int):String {
      if (_child == null) {
        return _vastOutput.ads[adId].creatives[creativeId].source.mediaFiles[0].uri;
        /*if (_vastOutput.ads[adId].creatives[creativeId].source.adParameters != null) {
        	return _vastOutput.ads[adId].creatives[creativeId].source.mediaFiles[0].uri +
        		"?" + unescape(_vastOutput.ads[adId].creatives[creativeId].source.adParameters);
        } else return _vastOutput.ads[adId].creatives[creativeId].source.mediaFiles[0].uri
        */
      }
      else return _child.getMediaUrl(adId, creativeId);
    }
    
    
    // tracking
    private function trackUri(uri:String):void {
      trace("tracking "+uri);
      
      if (uri != "") {
      	var urlRequest:URLRequest = new URLRequest(uri);
      	var urlLoader:URLLoader = new URLLoader();
      	urlLoader.load(urlRequest);
      }
    }
    private function getAdThis(adId:int):Ad {
      if (adId < _vastOutput.ads.length) {
        return _vastOutput.ads[adId];
      }
      return null;
    }
    private function getCreativeThis(adId:int, creativeId:int):Creative {
      var ad:Ad = getAdThis(adId);
      if (ad != null) {
        if (creativeId < ad.creatives.length) {
         return ad.creatives[creativeId];
        }
      }
      
      return null;
    }
    public function trackClick(adId:int, creativeId:int):void {
      var creative:Creative = getCreativeThis(adId, creativeId);
      if (creative != null) {
        for each (var ct:URIIdentifier in creative.source.videoClicks.clickTracking) {
						trackUri(ct.uri);
          }
      }
      
      if (_child != null) _child.trackClick(adId, creativeId);
    }
    public function trackImpression(adId:int):void {
      var ad:Ad = getAdThis(adId);
      if (ad != null) {
        for each (var it:URIIdentifier in ad.impressions) {
						trackUri(it.uri);
          }
      }
      
      if (_child != null) _child.trackImpression(adId);
    }
    public function trackEvent(adId:int, creativeId:int, type:String):void {
      var creative:Creative = getCreativeThis(adId, creativeId);
      if (creative != null) {
        for each (var te:TrackingEvent in creative.source.trackingEvents) {
            if (te.event == type) {
              trackUri(te.uri);
            }
          }
      }

      if (_child != null) _child.trackEvent(adId, creativeId, type);
    }
    
    
    public function get vast():VAST {
      return _vastOutput;
    }
  }
}
