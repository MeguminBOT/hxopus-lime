package hxopus;

import lime.app.Event;

/**
	Common interface for Opus streaming sources.
**/
interface IOpusSource {
	var onComplete:Event<Void->Void>;
	var gain(get, set):Float;
	var pitch(get, set):Float;
	var loops(get, set):Int;
	var currentTime(get, set):Int;
	/** Total length of the audio in milliseconds. Returns 0 if not seekable or not loaded. **/
	var length(get, never):Int;

	function play():Void;
	function pause():Void;
	function stop():Void;

	/**
		Keeps the streaming buffer queue fed.
		Call every frame inside your game loop.
	**/
	function update():Void;

	function dispose():Void;
}
