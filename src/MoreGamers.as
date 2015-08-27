package {
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.IOErrorEvent;
	
	import flash.system.Capabilities;
	import flash.utils.getTimer;
	
	import flash.display.Loader;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;

	public class MoreGamers {
		private static var _version:String = "1.0.2";

		private static var _id:int = 0;
		private static var _platform:String = null;
		
		private static var _ad:Object = null;
		private static var _banner:Loader = null;
		
		private static var _lastad:Number = 0;
		private static var _lastbanner:String = null;
		
		private static var _target:DisplayObjectContainer = null;
		private static var _x:Number = 0;
		private static var _y:Number = 0;
		private static var _width:Number = 0;
		private static var _height:Number = 0;
		
		public static function init(id:int):void {
			trace("init");
			
			_id = id;

			trace(Capabilities.version);
			if(Capabilities.version.indexOf('IOS') > -1) {
				_platform = "ios";
			} else if(Capabilities.version.indexOf('AND') > -1) {
				_platform = "android";

				// Read /system/build.prop to check for Amazon devices
				var prop:File = new File();
				prop.nativePath = '/system/build.prop';

				var fs:FileStream = new FileStream();
				fs.open(prop, FileMode.READ);

				var contents:String = fs.readUTFBytes(fs.bytesAvailable);
				contents = contents.replace(File.lineEnding, "\n");
				fs.close();

				var pattern:RegExp = /\r?\n/;
				var lines:Array = contents.split(pattern);

				for (var i:int = 0; i < lines.length; i++) {
					var line:String = String(lines[i]);
					var p:Array = line.split('=');
					if(p[0] == 'ro.product.brand' && p[1] == 'Amazon') {
						_platform = 'amazon';
					}
				}
			} else {
				_platform = "development";
			}

			fetchAd();
		}
		
		public static function banner(target:DisplayObjectContainer, x:Number, y:Number, width:Number, height:Number):void {
			trace("banner");
			
			if (_id < 1) return;
			
			_x = x;
			_y = y;
			_width  = width;
			_height = height;
			
			if(_banner == null) {
				_banner = new Loader();
				_banner.addEventListener(MouseEvent.CLICK, onBannerClick);
				_banner.contentLoaderInfo.addEventListener(Event.COMPLETE, onFetchBannerComplete);
				_banner.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onFetchBannerError);
			}
		
			target.addChild(_banner);
			
			fetchAd();
		}
		
		public static function removeBanner():void {
			trace("removeBanner");
			
			if (_banner !=  null && _banner.parent != null) {
				_banner.parent.removeChild(_banner);
				trace(_banner);
			}
		}

		private static function fetchAd():void {
			trace("fetchAd");
			
			if(_lastad == 0 || (getTimer() - _lastad) > 120000) {
				_lastad = getTimer();

				var jsl:URLLoader = new URLLoader();
				jsl.addEventListener(Event.COMPLETE, onFetchAdComplete);
				jsl.addEventListener(IOErrorEvent.IO_ERROR, onFetchAdError);
				jsl.load(new URLRequest("http://app.moregamers.com/ad?game=" + _id + "&platform=" + _platform + "&sdk=air&sdkVersion=" + _version));
			} else {
				fetchBanner();
			}
		}

		private static function onFetchAdError(e:IOErrorEvent):void {
			trace("onFetchAdError");
		}

		private static function onFetchAdComplete(e:Event):void {
			trace("onFetchAdComplete");
			
			_ad = JSON.parse(String(e.target.data));
			fetchBanner();
		}
		
		private static function fetchBanner():void {
			trace("fetchBanner");
			
			if (_ad == null) return;
			if (_banner == null) return;
			
			var url:String = (_width / _height > 1.5) ? _ad.portrait_image : _ad.landscape_image;
			if (url != _lastbanner) {
				_lastbanner = url;
				_banner.load(new URLRequest(url));
			} else {
				onFetchBannerComplete();
			}
		}

		private static function onFetchBannerError(e:IOErrorEvent):void {
			trace("onFetchBannerError");
		}

		private static function onFetchBannerComplete(e:Event=null):void {
			trace("onFetchBannerComplete");
			
			_banner.x = _x;
			_banner.y = _y;
			_banner.width  = _width;
			_banner.height = _height;
			
			if (_ad != null) {
				try {
					var track:URLLoader = new URLLoader();
					track.load(new URLRequest(_ad.tracking));
				} catch (e:Error) {
					trace(e.toString());
				}
			}
		}

		private static function onBannerClick(e:MouseEvent):void {
			trace("onBannerClick");
			
			if(_ad == null) return;

			var r:URLRequest = new URLRequest(_ad.click);
			try {
				navigateToURL(r, '_blank');
			} catch(e:Error) {
				trace(e.toString());
			}
		}
	}
}
