~frippbuffers[~currentfripp].write("/Users/mike/Music/SuperCollider Recordings/test.aiff");

~frippbuffer.write("/Users/mike/Music/SuperCollider Recordings/slow.aiff");
~frippbuffer.isNil;


(
~monitor = SynthDef(
	\monitor_synth,
	{
		arg in=2, out=0;
		Out.ar(out, In.ar(in, 2))
	}
).play(s, [\in, ~fxb, \out, 0 ], \addToTail);

)

~monitor.set(\in, ~reverbb)

~monitor.free

~pitchb.scope()

~frippbuffers.plot;

~bufrecorder.set(\buffer, ~frippbuffers[1]);


~granulators[0].get(\buffer, {|v| v.postln});

(
~frippbuffers.do({
	|b, i|
	b.write("/Users/mike/Music/SuperCollider Recordings/buffer" ++ i.asString ++ ".aiff");
});
)
