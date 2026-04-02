package hxopus;

import lime.media.AudioBuffer;
import haxe.io.Bytes;
import hxopus.externs.OpusFile;
import hxopus.util.OpusAudioBuffer;
import hxopus.util.OpusAudioSource;

class Opus {
	/**
		Load an Opus file for streaming playback.

		Returns an `OpusAudioSource` backed by OpenAL buffer queuing — call `update()` every frame.

		@param path Path to the `.opus` file.
		@return An `IOpusSource` ready to play, or `null` if the file could not be opened.
	**/
	public static function loadStream(path:String):IOpusSource {
		#if cpp
		var opusFile = OpusFile.fromFile(path);
		if (opusFile == null)
			return null;
		var buffer = OpusAudioBuffer.fromOpusFile(opusFile);
		return new OpusAudioSource(buffer, opusFile);
		#else
		return null;
		#end
	}

	/**
		Load an Opus stream from raw bytes for streaming playback.
		@param bytes Raw bytes of an OggOpus stream.
		@return An `IOpusSource` ready to play, or `null` on failure.
	**/
	public static function loadStreamFromBytes(bytes:Bytes):IOpusSource {
		#if cpp
		var opusFile = OpusFile.fromBytes(bytes);
		if (opusFile == null)
			return null;
		var buffer = OpusAudioBuffer.fromOpusFile(opusFile);
		return new OpusAudioSource(buffer, opusFile);
		#else
		return null;
		#end
	}

	/**
		Decode an Opus file into a standard lime `AudioBuffer`.
		The returned buffer works directly with `lime.media.AudioSource`.

		@param path Path to the `.opus` file.
		@return A decoded `AudioBuffer`, or `null` if the file could not be opened.
	**/
	public static function loadBuffer(path:String):AudioBuffer {
		#if cpp
		var opusFile = OpusFile.fromFile(path);
		if (opusFile == null)
			return null;
		return OpusAudioBuffer.fromOpusFileDecoded(opusFile);
		#else
		return null;
		#end
	}

	/**
		Decode an Opus stream from bytes into a standard lime `AudioBuffer`.

		@param bytes Raw bytes of an OggOpus stream.
		@return A decoded `AudioBuffer`, or `null` on failure.
	**/
	public static function loadBufferFromBytes(bytes:Bytes):AudioBuffer {
		#if cpp
		var opusFile = OpusFile.fromBytes(bytes);
		if (opusFile == null)
			return null;
		return OpusAudioBuffer.fromOpusFileDecoded(opusFile);
		#else
		return null;
		#end
	}
}
