package com.hinish.spec.xs
{

    /**
     * Represents an XML Schema time object. 
     *
     * @langversion 3.0
     * @playerversion Flash 10
     */
    public class Time extends Object
    {
        public function Time(value:String)
        {
            var parts:Array = value.split(":");
            if (parts.length > 1) {
            	hours = uint(parts[0]);
            	minutes = uint(parts[1]);
            	parts = parts[2].split(".");
              seconds = uint(parts[0]);
            	milliseconds = uint(parts[1]);
            }
            
        }
        public var hours:uint = 0;
        public var minutes:uint = 0;
        public var seconds:uint = 0;
        public var milliseconds:uint = 0;

        public function toString():String
        {
            return (hours < 10 ? "0" : "") + hours + ":" + (minutes < 10 ? "0" : "") + minutes + ":" + (seconds < 10 ? "0" : "") + seconds + "." + (milliseconds < 100 ? "0" : "") + (milliseconds < 10 ? "0" : "") + milliseconds;
        }
    }
}
