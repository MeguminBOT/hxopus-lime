package hxopus.externs;

import haxe.Int64;
import haxe.io.Bytes;

/**
	Wraps `libopusfile` for streaming decode of `.opus` / `.ogg-opus` files.

	Mirrors the interface of `lime.media.vorbis.VorbisFile` so that
	`OpusAudioSource` can follow the same streaming pattern lime uses for Vorbis.

	Differences from `VorbisFile`:
	- Opus always outputs signed 16-bit PCM at 48 kHz; no format params needed.
	- `read()` returns *samples per channel* decoded, not bytes.
**/
@:noCompletion @:unreflective
#if (cpp && !macro)
@:buildXml('<include name="${haxelib:hxopus-lime}/project/Build.xml"/>')
@:cppFileCode('
#include "opusfile.h"
')
#end
class OpusFile
{
	/** Currently active link index (for chained streams, usually 0) **/
	public var link(default, null):Int = 0;

	#if (cpp && !macro)
	@:noCompletion private var handle:cpp.RawPointer<cpp.Void>;

	@:noCompletion private function new(handle:cpp.RawPointer<cpp.Void>)
	{
		this.handle = handle;
	}
	#else
	@:noCompletion private function new(_:Dynamic) {}
	#end

	/**
		Open an Opus file from disk.

		@param path Path to the `.opus` file.
		@return A new `OpusFile`, or `null` if the file is not found or not a valid Opus stream.
	**/
	public static function fromFile(path:String):Null<OpusFile>
	{
		#if (cpp && !macro)
		var err:Int = 0;
		var handle:cpp.RawPointer<cpp.Void> = untyped __cpp__(
			"(void*)op_open_file({0}.c_str(), &{1})",
			path, err
		);
		if (untyped __cpp__("{0} == nullptr", handle) || err != 0)
			return null;
		return new OpusFile(handle);
		#else
		return null;
		#end
	}

	/**
		Open an Opus stream from in-memory bytes.
		The bytes must remain valid for the lifetime of this `OpusFile`.

		@param bytes Raw bytes of an OggOpus stream.
		@return A new `OpusFile`, or `null` on failure.
	**/
	public static function fromBytes(bytes:Bytes):Null<OpusFile>
	{
		#if (cpp && !macro)
		var err:Int = 0;
		var data = bytes.getData();
		var handle:cpp.RawPointer<cpp.Void> = untyped __cpp__(
			"(void*)op_open_memory((const unsigned char*)&({0}[0]), {1}, &{2})",
			data, bytes.length, err
		);
		if (untyped __cpp__("{0} == nullptr", handle) || err != 0)
			return null;
		return new OpusFile(handle);
		#else
		return null;
		#end
	}

	/**
		Decode up to `length` bytes of signed 16-bit interleaved PCM into
		`buffer` starting at `position`.

		@return Samples-per-channel decoded (>0), 0 at end-of-stream, or negative on error.
	**/
	public function read(buffer:Bytes, position:Int, length:Int = 4096):Int
	{
		#if (cpp && !macro)
		var channels:Int = untyped __cpp__("op_channel_count((const OggOpusFile*)(void*){0}, -1)", handle);
		if (channels <= 0)
			return 0;
		var samplesPerCh:Int = Std.int(length / 2 / channels);
		var data = buffer.getData();
		var result:Int = untyped __cpp__(
			"op_read((OggOpusFile*)(void*){0}, (opus_int16*)&({1}[{2}]), {3}, nullptr)",
			handle, data, position, samplesPerCh
		);
		return result;
		#else
		return 0;
		#end
	}

	/**
		Returns stream info: `channels` (1 or 2) and `sampleRate` (always 48000).
	**/
	public function info():OpusInfo
	{
		#if (cpp && !macro)
		var info = new OpusInfo();
		info.channels = untyped __cpp__("op_channel_count((const OggOpusFile*)(void*){0}, -1)", handle);
		info.sampleRate = 48000;
		info.version = 0;
		return info;
		#else
		return null;
		#end
	}

	/**
		Convenience: returns the channel count without allocating an `OpusInfo`.
	**/
	public function channelCount():Int
	{
		#if (cpp && !macro)
		return untyped __cpp__("op_channel_count((const OggOpusFile*)(void*){0}, -1)", handle);
		#else
		return 0;
		#end
	}

	/**
		Seek to a PCM sample position.

		@return 0 on success, negative on error.
	**/
	public function pcmSeek(pos:Int64):Int
	{
		#if (cpp && !macro)
		return untyped __cpp__("op_pcm_seek((OggOpusFile*)(void*){0}, {1})", handle, pos);
		#else
		return 0;
		#end
	}

	/** @return The current PCM read position in samples. **/
	public function pcmTell():Int64
	{
		#if (cpp && !macro)
		return untyped __cpp__("op_pcm_tell((const OggOpusFile*)(void*){0})", handle);
		#else
		return Int64.ofInt(0);
		#end
	}

	/** @return Total PCM sample count, or -1 if not seekable. **/
	public function pcmTotal():Int64
	{
		#if (cpp && !macro)
		return untyped __cpp__("op_pcm_total((const OggOpusFile*)(void*){0}, -1)", handle);
		#else
		return Int64.ofInt(-1);
		#end
	}

	/** @return `true` if the stream supports seeking. **/
	public function seekable():Bool
	{
		#if (cpp && !macro)
		return (untyped __cpp__("op_seekable((const OggOpusFile*)(void*){0})", handle) : Int) != 0;
		#else
		return false;
		#end
	}

	/**
		Free the underlying handle. Must not be used after this call.
	**/
	public function clear():Void
	{
		#if (cpp && !macro)
		if (untyped __cpp__("{0} != nullptr", handle))
		{
			untyped __cpp__("op_free((OggOpusFile*)(void*){0})", handle);
			handle = untyped __cpp__("nullptr");
		}
		#end
	}
}
