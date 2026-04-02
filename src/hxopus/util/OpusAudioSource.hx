package hxopus.util;

import lime.media.AudioBuffer;
import lime.media.openal.AL;
import lime.media.openal.ALBuffer;
import lime.media.openal.ALSource;
import lime.utils.UInt8Array;
import haxe.io.Bytes;
import hxopus.externs.OpusFile;

/**
	Streaming `AudioSource` backend for Opus files on CPP.

	Maintains a ring of `NUM_BUFFERS` OpenAL buffers that are continuously
	filled from an `OpusFile` and queued onto the `ALSource`. This mirrors
	the double/triple-buffer streaming pattern lime uses for Vorbis.
**/
class OpusAudioSource implements IOpusSource {
	/** Number of OpenAL buffers in the ring. 3 gives comfortable headroom at 60fps; increase if you hear dropouts. **/
	static inline var NUM_BUFFERS = 3;

	/** Bytes per decode chunk fed to OpenAL. 4096 bytes ≈ 21ms at 48kHz stereo 16-bit. **/
	static inline var CHUNK_BYTES = 4096;

	public var onComplete = new lime.app.Event<Void->Void>();

	public var gain(get, set):Float;
	public var pitch(get, set):Float;
	public var loops(get, set):Int;
	public var currentTime(get, set):Int;
	public var length(get, never):Int;

	var _opusFile:OpusFile;

	var _alSource:ALSource;
	var _alBuffers:Array<ALBuffer>;
	var _chunkBytes:Bytes; // reusable decode scratch buffer

	var _channels:Int;
	var _alFormat:Int;

	var _playing:Bool = false;
	var _loops:Int = 0;
	var _gain:Float = 1.0;
	var _pitch:Float = 1.0;

	var _eof:Bool = false;

	public function new(buffer:AudioBuffer, opusFile:OpusFile) {
		_opusFile = opusFile;

		_channels = buffer.channels;
		_alFormat = (_channels == 2) ? AL.FORMAT_STEREO16 : AL.FORMAT_MONO16;
		_chunkBytes = Bytes.alloc(CHUNK_BYTES);

		// Allocate OpenAL source and buffer ring
		_alSource = AL.createSource();
		_alBuffers = [];
		for (i in 0...NUM_BUFFERS) {
			_alBuffers.push(AL.createBuffer());
		}
	}

	public function play():Void {
		if (_playing)
			return;
		_playing = true;
		_eof = false;

		AL.sourcef(_alSource, AL.GAIN, _gain);
		AL.sourcef(_alSource, AL.PITCH, _pitch);

		// Prime all buffers before starting playback
		for (alBuf in _alBuffers) {
			if (!_fillBuffer(alBuf))
				break;
			AL.sourceQueueBuffers(_alSource, 1, [alBuf]);
		}

		AL.sourcePlay(_alSource);
	}

	public function pause():Void {
		if (!_playing)
			return;
		_playing = false;
		AL.sourcePause(_alSource);
	}

	public function stop():Void {
		_playing = false;
		AL.sourceStop(_alSource);
		_unqueueAll();
		if (_opusFile != null && _opusFile.seekable()) {
			_opusFile.pcmSeek(haxe.Int64.ofInt(0));
		}
		_eof = false;
	}

	public function update():Void {
		if (!_playing)
			return;

		// How many buffers has OpenAL finished consuming?
		var processed = AL.getSourcei(_alSource, AL.BUFFERS_PROCESSED);

		while (processed-- > 0) {
			var unqueued:Array<ALBuffer> = AL.sourceUnqueueBuffers(_alSource, 1);
			if (unqueued == null || unqueued.length == 0)
				break;
			var alBuf = unqueued[0];

			if (_eof)
				continue;

			if (!_fillBuffer(alBuf)) {
				if (_loops != 0) {
					if (_loops > 0)
						_loops--;
					_opusFile.pcmSeek(haxe.Int64.ofInt(0));
					if (_fillBuffer(alBuf)) {
						AL.sourceQueueBuffers(_alSource, 1, [alBuf]);
					}
				} else {
					_eof = true;
				}
			} else {
				AL.sourceQueueBuffers(_alSource, 1, [alBuf]);
			}
		}

		var state = AL.getSourcei(_alSource, AL.SOURCE_STATE);
		if (_playing && !_eof && state != AL.PLAYING) {
			AL.sourcePlay(_alSource);
		}

		if (_eof) {
			var queued = AL.getSourcei(_alSource, AL.BUFFERS_QUEUED);
			if (queued == 0) {
				_playing = false;
				onComplete.dispatch();
			}
		}
	}

	public function dispose():Void {
		stop();
		AL.deleteSource(_alSource);
		AL.deleteBuffers(_alBuffers);
		_alSource = null;
		_alBuffers = null;
		if (_opusFile != null) {
			_opusFile.clear();
			_opusFile = null;
		}
	}

	/**
		Decodes one chunk from the `OpusFile` into `alBuf`.

		@param alBuf The OpenAL buffer to fill.
		@return `true` if data was written; `false` at EOF or on error.
	**/
	function _fillBuffer(alBuf:ALBuffer):Bool {
		var samplesPerChannel = _opusFile.read(_chunkBytes, 0, CHUNK_BYTES);
		if (samplesPerChannel <= 0)
			return false;

		var bytesProduced = samplesPerChannel * _channels * 2; // 16-bit = 2 bytes per sample

		var data = UInt8Array.fromBytes(_chunkBytes, 0, bytesProduced);
		AL.bufferData(alBuf, _alFormat, data, bytesProduced, 48000);
		return true;
	}

	function _unqueueAll():Void {
		var queued = AL.getSourcei(_alSource, AL.BUFFERS_QUEUED);
		if (queued > 0) {
			AL.sourceUnqueueBuffers(_alSource, queued);
		}
	}

	function get_gain():Float
		return _gain;

	function set_gain(v:Float):Float {
		_gain = v;
		if (_alSource != null)
			AL.sourcef(_alSource, AL.GAIN, v);
		return v;
	}

	function get_pitch():Float
		return _pitch;

	function set_pitch(v:Float):Float {
		_pitch = v;
		if (_alSource != null)
			AL.sourcef(_alSource, AL.PITCH, v);
		return v;
	}

	function get_loops():Int
		return _loops;

	function set_loops(v:Int):Int {
		_loops = v;
		return v;
	}

	function get_currentTime():Int {
		if (_opusFile == null)
			return 0;
		// Convert PCM sample position to milliseconds.
		var samplePos = haxe.Int64.toInt(_opusFile.pcmTell());
		return Std.int(samplePos / 48000 * 1000);
	}

	function get_length():Int {
		if (_opusFile == null)
			return 0;
		var total = _opusFile.pcmTotal();
		var totalInt = haxe.Int64.toInt(total);
		return totalInt < 0 ? 0 : Std.int(totalInt / 48000 * 1000);
	}

	function set_currentTime(ms:Int):Int {
		if (_opusFile != null && _opusFile.seekable()) {
			var sample = haxe.Int64.ofInt(Std.int(ms / 1000 * 48000));
			_opusFile.pcmSeek(sample);
			var wasPlaying = _playing;
			if (wasPlaying) {
				AL.sourceStop(_alSource);
				_unqueueAll();
				_eof = false;
				for (alBuf in _alBuffers) {
					if (!_fillBuffer(alBuf))
						break;
					AL.sourceQueueBuffers(_alSource, 1, [alBuf]);
				}
				AL.sourcePlay(_alSource);
			}
		}
		return ms;
	}
}
