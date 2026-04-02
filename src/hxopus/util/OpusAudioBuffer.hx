package hxopus.util;

import lime.media.AudioBuffer;
import lime.utils.UInt8Array;
import haxe.io.Bytes;
import hxopus.externs.OpusFile;

class OpusAudioBuffer {
	/**
		@param opusFile An open `OpusFile` handle.
		@return A streaming `AudioBuffer`, or `null` if `opusFile` is null or has no stream info.
	**/
	public static function fromOpusFile(opusFile:OpusFile):AudioBuffer {
		if (opusFile == null)
			return null;

		var info = opusFile.info();
		if (info == null)
			return null;

		var buffer = new AudioBuffer();
		buffer.channels = info.channels;
		buffer.sampleRate = 48000; // Opus always outputs 48 kHz
		buffer.bitsPerSample = 16; // op_read always outputs signed 16-bit

		return buffer;
	}

	/**
		@param opusFile An open `OpusFile` handle.
		@return A fully decoded `AudioBuffer`, or `null` if `opusFile` is null or has no stream info.
	**/
	public static function fromOpusFileDecoded(opusFile:OpusFile):AudioBuffer {
		if (opusFile == null)
			return null;

		var info = opusFile.info();
		if (info == null)
			return null;

		// Decode all PCM in chunks, accumulating into a growing list.
		final CHUNK = 4096; // bytes per read call
		var chunks:Array<Bytes> = [];
		var totalBytes = 0;
		var chunk = Bytes.alloc(CHUNK);

		while (true) {
			var samplesPerChannel = opusFile.read(chunk, 0, CHUNK);
			if (samplesPerChannel <= 0)
				break;
			var bytesProduced = samplesPerChannel * info.channels * 2; // 16-bit = 2 bytes per sample
			var copy = Bytes.alloc(bytesProduced);
			copy.blit(0, chunk, 0, bytesProduced);
			chunks.push(copy);
			totalBytes += bytesProduced;
		}

		opusFile.clear();

		// Merge all chunks into a single Bytes
		var allPCM = Bytes.alloc(totalBytes);
		var offset = 0;
		for (c in chunks) {
			allPCM.blit(offset, c, 0, c.length);
			offset += c.length;
		}

		var buffer = new AudioBuffer();
		buffer.channels = info.channels;
		buffer.sampleRate = 48000;
		buffer.bitsPerSample = 16;
		buffer.data = new UInt8Array(allPCM);

		return buffer;
	}
}
