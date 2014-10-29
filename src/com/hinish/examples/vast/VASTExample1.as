package com.hinish.examples.vast
{
    import flash.events.NetStatusEvent;
    import flash.events.Event;
    import flash.display.MovieClip;
    import flash.net.URLRequest;
    import flash.net.navigateToURL;
    import com.hinish.spec.iab.vast.vos.Creative;
    import flash.events.MouseEvent;
    import flash.net.NetStream;
    import flash.net.NetConnection;
    import com.hinish.spec.iab.vast.vos.MediaFile;
    import flash.media.Video;
    import flash.display.Loader;
    import com.curvefever.vastplayer.TestUtils;
    import com.hinish.examples.vast.extensions.parsers.DARTInfoParser;
    import com.hinish.examples.vast.extensions.parsers.PreviousAdInformationParser;
    import com.hinish.spec.iab.vast.parsers.VASTParser;
    import com.hinish.spec.iab.vast.vos.VAST;

    import flash.display.Sprite;
    import flash.utils.ByteArray;
    import flash.utils.setTimeout;


    public class VASTExample1 extends Sprite
    {
        [Embed(source = "../../../../../examples/resources/vast_sample_1.xml", mimeType = "application/octet-stream")]
        private static const SAMPLE_1:Class;
        
        [Embed(source = "../../../../../examples/resources/vast_sample_2.xml", mimeType = "application/octet-stream")]
        private static const SAMPLE_2:Class;
        
        [Embed(source = "../../../../../examples/resources/vast_reallife.xml", mimeType = "application/octet-stream")]
        private static const SAMPLE_3:Class;
        
        
        private var vidHolder:MovieClip;
        
        public function VASTExample1()
        {
            //setTimeout(parseVast, 2500);
            parseVast();
        }
        
        private function parseVast():void
        {
            var parser:VASTParser = new VASTParser();
            parser.registerExtensionParser(new PreviousAdInformationParser());
            parser.registerExtensionParser(new DARTInfoParser());
            
            parser.setData(XML(getContents(SAMPLE_1)));
            var output1:VAST = parser.parse();
            
            parser.setData(XML(getContents(SAMPLE_2)));
            var output2:VAST = parser.parse();
            
            parser.setData(XML(getContents(SAMPLE_3)));
            var output3:VAST = parser.parse();
            
            trace("test");
            TestUtils.deepTrace(output1,100);
            TestUtils.deepTrace(output2,100);
            TestUtils.deepTrace(output3,100);
	
            
            var creative:Creative = output3.ads[0].creatives[0];
            // 0 - 4 - 10
            var mediaFile:MediaFile = creative.source.mediaFiles[10];
            
            vidHolder = new MovieClip();
            addChild(vidHolder);
            
            var vid:Video = new Video(mediaFile.width, mediaFile.height);
						vidHolder.addChild(vid);
            vidHolder.buttonMode = true;
            
            vidHolder.addEventListener(MouseEvent.CLICK, function (e:MouseEvent):void {
              var clickThroughUrl:String = creative.source.videoClicks.clickThrough.uri;
              navigateToURL(new URLRequest(clickThroughUrl),"_blank");
            });
            var ratioW:Number = 1024/mediaFile.width;
            var ratioH:Number = 768/mediaFile.height;
            vid.scaleX = vid.scaleY = Math.min(ratioW, ratioH);
						
						var nc:NetConnection = new NetConnection();
						nc.connect(null);
						
						var ns:NetStream = new NetStream(nc);
						vid.attachNetStream(ns);
            
            ns.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
						
						var listener:Object = new Object();
						listener.onMetaData = function(evt:Object):void {};
						ns.client = listener;
						
						ns.play(mediaFile.uri);
            
            trace(mediaFile.uri, mediaFile.bitrate, mediaFile.width, mediaFile.height);
        }

				private function onNetStatus(e:NetStatusEvent):void {
          trace(e.info.code);
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
          if (e.info.code == "NetStream.Play.Stop") removeChild(vidHolder);
        }

        private function getContents(cls:Class):String
        {
            var ba:ByteArray = new cls();
            return ba.readUTFBytes(ba.length);
        }
    }
}
