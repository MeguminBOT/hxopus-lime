package hxopus.externs;

/**
	Metadata for an Opus stream.
	Mirrors `lime.media.vorbis.VorbisInfo` for API consistency.
**/
class OpusInfo {
	/** Number of channels (1 = mono, 2 = stereo) **/
	public var channels:Int = 0;

	/** Always 48000 for Opus **/
	public var sampleRate:Int = 48000;

	/** Opus version from the stream header **/
	public var version:Int = 0;

	public function new() {}
}
