// Execute this before booting the server

(
Server.default.options.inDevice_("Scarlett 2i2 USB");
//Server.default.options.outDevice_("Scarlett 2i2 USB");
)
Server.killAll;


("./synths.scd").loadRelative;
("./control.scd").loadRelative;
("./effects.scd").loadRelative;

Granulator.init(s);





(
// set up four position buffers with synths

~modes = [
	[ "saw", \pos_saw ],
	[ "reverse", \pos_reverse ],
	[ "sine", \pos_sine ],
	[ "step", \pos_step ],
	[ "random", \pos_rand ]
];

~granulators = Array.new(4);
~posb = Array.new(4);
~possynth = Array.new(4);

(0..3).do({
	var pb = Bus.control(s, 1), ps;
	~posb.add(pb);
	ps = Synth(\pos_saw, [ \out, pb ]);
	~possynth.add(ps);
});

)

(

(0..3).do({ |i|
	var pb = ~posb.at(i);
	~granulators.add(Granulator.new(~buflen, ~recordb, ~outb, pb, ~triggerb, ~pitchb));
});

)

~granulators[1].record(1.0);
~possynth[0].set(\speed,200);

("./interface.scd").loadRelative;



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






