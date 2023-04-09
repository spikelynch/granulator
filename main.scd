// Execute this before booting the server

(
Server.default.options.inDevice_("Scarlett 2i2 USB");
//Server.default.options.outDevice_("Scarlett 2i2 USB");
)
Server.killAll;
~frippbuffer.write("/Users/mike/Music/SuperCollider Recordings/slow.aiff");
~frippbuffer.isNil;


("./synths.scd").loadRelative;
("./control.scd").loadRelative;
("./effects.scd").loadRelative;

~modes = [
	[ "saw", \pos_saw ],
	[ "reverse", \pos_reverse ],
	[ "sine", \pos_sine ],
	[ "step", \pos_step ],
	[ "random", \pos_rand ]
];



Granulator.init(s)

~g3 = Granulator.new(4, ~recordb, ~granulatorb, ~playbacklfob, ~triggerb, ~pitchb);

~g.recorder.set(\record, 1.0);
~makebuffers.value();

(
~bufrecorders = Array.new(~ntracks);

~frippbuffers.do({
	| buffer, index |
	~bufrecorders.add(Synth.new(
		\fripp_record,
		[
			\in, ~recordb,
			\record, 0.0,
			\buffer, buffer
		],
		s,
		\addToTail
	))
});

~bufrecorder = ~bufrecorders[0];

// the granulators

~granulators = Array.new(~ntracks);
~grainmodes = Array.fill(~ntracks, 0);

~frippbuffers.do({
	| buffer, index |
	[ "Grain synth: ", buffer, index ].postln;
	~granulators.add(Synth.new(
		\grainsynth,
		[
			\out, ~granulatorb,
			\buffer, buffer,
			\blen, ~buflen,
			\posb, ~playbacklfob,
			\triggerb, ~triggerb,
			\pitchb, ~pitchb,
			\modb, ~lfob,
			\size, 0.1
		],
		s
	))
});

~granulator = ~granulators[0];

)






~frippbuffers[~currentfripp].write("/Users/mike/Music/SuperCollider Recordings/test.aiff");

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
