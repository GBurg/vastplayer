package com.curvefever.vastplayer {
  import com.hinish.spec.iab.vast.vos.Creative;
  import com.hinish.spec.iab.vast.vos.MediaFile;
  import com.hinish.spec.iab.vast.vos.TrackingEventTypes;
  import com.hinish.spec.iab.vpaid.AdEvent;
  import com.hinish.spec.iab.vpaid.AdViewMode;
  import com.hinish.spec.xs.Time;

  import org.osmf.net.NetStreamCodes;

  import flash.display.Loader;
  import flash.display.MovieClip;
  import flash.display.Sprite;
  import flash.events.Event;
  import flash.events.EventDispatcher;
  import flash.events.IOErrorEvent;
  import flash.events.MouseEvent;
  import flash.events.NetStatusEvent;
  import flash.events.TimerEvent;
  import flash.media.SoundTransform;
  import flash.media.Video;
  import flash.net.NetConnection;
  import flash.net.NetStream;
  import flash.net.URLRequest;
  import flash.net.navigateToURL;
  import flash.system.ApplicationDomain;
  import flash.system.LoaderContext;
  import flash.system.Security;
  import flash.system.SecurityDomain;
  import flash.utils.Timer;
  import flash.utils.getTimer;

  /**
   * @author Geert
   */
  public class VASTplayer extends Sprite {
    
    public static const DURATION:String = "VASTplayer duration";
    public static const NO_ADS:String = "VASTplayer skip";
    
    public var autoSkip:int;
    private var _vastManager:VASTManager;
    private var _vpaid:*; 
    
   
    //private var _vastOutput:VAST;
    private var _vidHolder:MovieClip;
    private var _video:Video;
    private var _appLoader:Loader;
    private var _adType:String;
    //private var _clickThroughUrl:String;
    private var _nc:NetConnection;
    private var _ns:NetStream;
    private var _quartileTimer:Timer;
    
    private var _adDuration:int = -1; // in ms;
    
    public function VASTplayer() {
      
      TestUtils.log("test");
      
      _vastManager = new VASTManager();
      _vastManager.addEventListener(VASTManager.LOADED, onLoaded);
      _vastManager.addEventListener(VASTManager.NOADS, onNoAds);
      
      _appLoader = new Loader();
      _appLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onAppComplete);
      _appLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
      
      _vidHolder = new MovieClip();
      _vidHolder.addEventListener(MouseEvent.CLICK, onClickVideo);
      _nc = new NetConnection();
			_nc.connect(null);
      _ns = new NetStream(_nc);
      _ns.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
      
      _quartileTimer = new Timer(30000/4,4);
      _quartileTimer.addEventListener(TimerEvent.TIMER, onQuartileUpdate);
      
      //init("http://www.adotube.com/php/services/player/OMLService.php?avpid=4WGV9QE&platform_version=vast20&ad_type=linear&companion=0&HTTP_REFERER=http://curvefever.com/play2.php&video_identifier=http://curvefever.com, CurveFever2, 2, http://curvefever.com/CurveFever2.swf");
      //init("http://ads.curvefever.com/www/delivery/fc.php?script=apVideo:vast2&zoneid=4");
      //play();
      
    }
    
    public function init(vastUrl:String, maxTime:int = 30, autoSkip:int = 40):void {
      TestUtils.log("player - init");
      this.autoSkip = autoSkip;
      _vastManager.init(vastUrl, null, maxTime, "FLV");
      setAdDuration(maxTime*1000);
    }
    
    public function play():void {
      TestUtils.log("player - play");
      _vastManager.load();
      
      
      
      // the steps we have to take:
      // 1 load the xml from the server
      //loadXMLFromServer(vastUrl);
      // 2 parse the vast
      
      // 3 see if it is a redirect (if so, repeat step 1) else go to step 4
      //trace("show deep trace");
      // 4 show video
      
      
      
    }
    private function onNoAds(e:Event):void {
      dispatchEvent(new Event(NO_ADS));
    }
    
    private function onLoaded(e:Event):void {
      TestUtils.log("player - onLoaded");
      showvideo();
    }
    private function showvideo():void {
      TestUtils.log("player - showvideo");
      
      
      //var ad:Ad = _vastManager.getAd(0);
      //var creative:Creative = _vastManager.getCreative(0,0);
      var mediaFile:MediaFile = _vastManager.getMediaFile(0,0);
      var mediaUrl:String = _vastManager.getMediaUrl(0, 0);
      
      var t:Time = _vastManager.getDuration(0, 0);
      setAdDuration(t.hours*3600000 + t.minutes*60000 + t.seconds*1000 + t.milliseconds);
      
      if (mediaFile.apiFramework.toUpperCase() == "VPAID") {
        TestUtils.log("player - showvideo - VPAID");
        _adType = "VPAID";
        // we need to load the application
        //mediaUrl = "http://curvefever.com/explanation_guest.swf";
        //trace(mediaUrl);
        var appRequest:URLRequest = new URLRequest(mediaUrl);
        
        
        // start loading of mainMovie.swf
	      var context:LoaderContext;
	      if (Security.sandboxType == Security.REMOTE) {
	        context = new LoaderContext(true, ApplicationDomain.currentDomain, SecurityDomain.currentDomain);
	      } else {
	        context = null;
	      }
        _appLoader.load(appRequest, context);
        
      } else {
        TestUtils.log("player - showvideo - VAST");
      	_adType = "VAST";
      
	      addChild(_vidHolder);
	     _video = new Video(mediaFile.width, mediaFile.height);
				_vidHolder.addChild(_video);
	      _vidHolder.buttonMode = true;
	      //_clickThroughUrl = video.source.videoClicks.clickThrough.uri;
	
	      var ratioW:Number = stage.stageWidth/mediaFile.width;
	      var ratioH:Number = stage.stageHeight/mediaFile.height;
	      _video.scaleX = _video.scaleY = Math.min(ratioW, ratioH);
	      
				_video.attachNetStream(_ns);
				
				var listener:Object = new Object();
				listener.onMetaData = onMetaData;
	      
				_ns.client = listener;
				_ns.play(mediaUrl);
        
        _vastManager.trackEvent(0,0, TrackingEventTypes.CREATIVE_VIEW);
      }
      
      
      
    }
    // VPAID handling
		private function ioErrorHandler(e:IOErrorEvent):void {
      TestUtils.log("player - ioErrorHandler - "+e);
      trace(e);
    }
    private function onAppComplete(e:Event):void {
      TestUtils.log("player - onAppComplete");
      
      var creative:Creative = _vastManager.getCreative(0, 0);
      trace(unescape(creative.source.adParameters));
      addChild(_vidHolder);
      _vpaid = _appLoader.content;
      addChild(_appLoader.content);
      
      _vpaid.handshakeVersion("2.0");
      
      _vpaid.initAd(stage.stageWidth, stage.stageHeight, AdViewMode.NORMAL, 500, creative.source.adParameters, stage.frameRate);
      EventDispatcher(_vpaid).addEventListener(AdEvent.AD_LOADED, onAdLoaded);
      EventDispatcher(_vpaid).addEventListener(AdEvent.AD_STARTED, onAdStarted);
      EventDispatcher(_vpaid).addEventListener(AdEvent.AD_STOPPED, onAdStopped);
      EventDispatcher(_vpaid).addEventListener(AdEvent.AD_IMPRESSION, onAdImpression);
      EventDispatcher(_vpaid).addEventListener(AdEvent.AD_VIDEO_START, onAdVideoEvent);
      EventDispatcher(_vpaid).addEventListener(AdEvent.AD_VIDEO_FIRST_QUARTILE, onAdVideoEvent);
      EventDispatcher(_vpaid).addEventListener(AdEvent.AD_VIDEO_MIDPOINT, onAdVideoEvent);
      EventDispatcher(_vpaid).addEventListener(AdEvent.AD_VIDEO_THIRD_QUARTILE, onAdVideoEvent);
      EventDispatcher(_vpaid).addEventListener(AdEvent.AD_VIDEO_COMPLETE, onAdVideoEvent);
      EventDispatcher(_vpaid).addEventListener(AdEvent.AD_CLICK_THRU, onAdClickThru);
      
    }
    private function onAdClickThru(e:*):void {
      TestUtils.log("player - onAdClickThru");
      var url:String = e.data.url;
      //var id:String = e.data.Id;
      var playerHandles:Boolean = e.data.playerHandles as Boolean;
      
      if (playerHandles) {
        if (!url) url = _vastManager.getClickThroughUrl(0,0);
        navigateToURL(new URLRequest(url),"_blank");
      }
      
      _vidHolder.soundTransform = new SoundTransform(0);
      _vastManager.trackClick(0, 0);
      _vpaid.adVolume = 0;
    }
    private function onAdVideoEvent(e:Event):void {
      TestUtils.log("player - onAdVideoEvent - "+e.type);
      if (e.type == AdEvent.AD_VIDEO_START) _vastManager.trackEvent(0, 0, TrackingEventTypes.START);
      if (e.type == AdEvent.AD_VIDEO_FIRST_QUARTILE) _vastManager.trackEvent(0, 0, TrackingEventTypes.FIRST_QUARTILE);
      if (e.type == AdEvent.AD_VIDEO_MIDPOINT) _vastManager.trackEvent(0, 0, TrackingEventTypes.MIDPOINT);
      if (e.type == AdEvent.AD_VIDEO_THIRD_QUARTILE) _vastManager.trackEvent(0, 0, TrackingEventTypes.THIRD_QUARTILE);
      if (e.type == AdEvent.AD_VIDEO_COMPLETE) _vastManager.trackEvent(0, 0, TrackingEventTypes.COMPLETE);
    }
    private function onAdImpression(e:Event):void {
      TestUtils.log("player - onAdImpression");
      trace("onImpression");
      _vastManager.trackImpression(0);
    }
    private function onAdLoaded(e:Event):void {
      TestUtils.log("player - onAdLoaded");
      _vpaid.startAd();
    }
    private function onAdStarted(e:Event):void {
      TestUtils.log("player - onAdStarted");
      if (_vpaid.adLinear) {
        _vastManager.trackEvent(0, 0, TrackingEventTypes.CREATIVE_VIEW);
        //IVPAIDAd
       	trace(_vpaid.adDuration, "duration"); // -1 not implemented, -2 if unknown
       	if (_vpaid.adDuration > 0) {
          setAdDuration(_vpaid.adDuration*1000);
        }
       	_vpaid.adVolume = 1;
        _vpaid.expandAd();
      }
      
    }
    private function onAdStopped(e:Event):void {
      TestUtils.log("player - onAdStopped");
      finished();
    }
    // VAST handling
		private function onClickVideo(e:MouseEvent):void {
      TestUtils.log("player - onClickVideo");
      var clickUrl:String = _vastManager.getClickThroughUrl(0,0);
      if (clickUrl != null) {
      	navigateToURL(new URLRequest(clickUrl),"_blank");
      	_vidHolder.soundTransform = new SoundTransform(0);
      
      }
      _vastManager.trackClick(0,0);
    }
    private function onMetaData(e:Object):void {
      TestUtils.log("player - onMetaData");
      trace("metadata: duration=" + e.duration + " framerate=" + e.framerate);
      setAdDuration(e.duration*1000);
      _quartileTimer.delay = e.duration*1000/4;//(t.hours*3600000 + t.minutes*60000 + t.seconds*1000 + t.milliseconds)/4;
      _quartileTimer.start();
      trace(getTimer(), _quartileTimer.delay, e.duration*1000/4);
    }
    private function onQuartileUpdate(e:TimerEvent):void {
      TestUtils.log("player - onQuartileUpdate - "+Timer(e.target).currentCount);
      var cc:int = Timer(e.target).currentCount;
      if (cc == 1) _vastManager.trackEvent(0, 0, TrackingEventTypes.FIRST_QUARTILE);
      if (cc == 2) _vastManager.trackEvent(0, 0, TrackingEventTypes.MIDPOINT);
      if (cc == 3) _vastManager.trackEvent(0, 0, TrackingEventTypes.THIRD_QUARTILE);
      
      trace(getTimer(), cc, Timer(e.target).currentCount*Timer(e.target).delay);
    }
    private function onNetStatus(e:NetStatusEvent):void {
      TestUtils.log("player - onNetStatus");
      trace(getTimer(), e.info.code);
      trace("");
      /*
       	NetStream.Play.Start
				NetStream.Buffer.Full
				NetStream.Buffer.Flush
				NetStream.Play.Stop
				NetStream.Buffer.Empty
       */
      //trace("movie finished");
      //removeChild(vidHolder);
      
      if (e.info.code == NetStreamCodes.NETSTREAM_PLAY_START) {
        //_quartileTimer.start();
        _vastManager.trackEvent(0,0, TrackingEventTypes.START);
        
      } else if (e.info.code == NetStreamCodes.NETSTREAM_BUFFER_FULL) {
        
      } else if (e.info.code == NetStreamCodes.NETSTREAM_BUFFER_FLUSH) {
        // finished streaming
        _vastManager.trackImpression(0);
      } else if (e.info.code == NetStreamCodes.NETSTREAM_PLAY_STOP) {
        // video finished
        _vastManager.trackEvent(0,0, TrackingEventTypes.COMPLETE);
        _vastManager.trackEvent(0,0, TrackingEventTypes.CLOSE);
        finished();
      } else if (e.info.code == NetStreamCodes.NETSTREAM_BUFFER_EMPTY) {
        
      }
    }
    
    
    
    private function finished():void {
      TestUtils.log("player - finished");
      dispatchEvent(new Event(Event.COMPLETE));
    }
    
    public function close():void {
      TestUtils.log("player - close");
      _vastManager.removeEventListener(VASTManager.LOADED, onLoaded);
      _vastManager.removeEventListener(VASTManager.NOADS, onNoAds);
      _appLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onAppComplete);
      _appLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
      _vidHolder.removeEventListener(MouseEvent.CLICK, onClickVideo);
      _ns.removeEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
      _quartileTimer.removeEventListener(TimerEvent.TIMER, onQuartileUpdate);
      
      if (_adType == "VPAID") {
        _vpaid.stopAd();
        
        EventDispatcher(_vpaid).removeEventListener(AdEvent.AD_LOADED, onAdLoaded);
	      EventDispatcher(_vpaid).removeEventListener(AdEvent.AD_STARTED, onAdStarted);
	      EventDispatcher(_vpaid).removeEventListener(AdEvent.AD_STOPPED, onAdStopped);
	      EventDispatcher(_vpaid).removeEventListener(AdEvent.AD_IMPRESSION, onAdImpression);
	      EventDispatcher(_vpaid).removeEventListener(AdEvent.AD_VIDEO_START, onAdVideoEvent);
	      EventDispatcher(_vpaid).removeEventListener(AdEvent.AD_VIDEO_FIRST_QUARTILE, onAdVideoEvent);
	      EventDispatcher(_vpaid).removeEventListener(AdEvent.AD_VIDEO_MIDPOINT, onAdVideoEvent);
	      EventDispatcher(_vpaid).removeEventListener(AdEvent.AD_VIDEO_THIRD_QUARTILE, onAdVideoEvent);
	      EventDispatcher(_vpaid).removeEventListener(AdEvent.AD_VIDEO_COMPLETE, onAdVideoEvent);
	      EventDispatcher(_vpaid).removeEventListener(AdEvent.AD_CLICK_THRU, onAdClickThru);
        
        removeChild(_vidHolder);
      } else if (_adType == "VAST") {
        _video.attachNetStream(null);
        _ns.close();
        removeChild(_vidHolder);
      }
      
    }
    
    public function setAdDuration(duration:int):void {
      TestUtils.log("player - setAdDuration");
      _adDuration = duration;
      dispatchEvent(new Event(DURATION));
    }
    public function getAdDuration():int {
      TestUtils.log("player - getAdDuration"); 
      return _adDuration; 
    }
    
  }
}
