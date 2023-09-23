

(
~modes = [
	[ "saw", \pos_saw ],
	[ "reverse", \pos_reverse ],
	[ "sine", \pos_sine ],
	[ "step", \pos_step ],
	[ "random", \pos_random ]
];

~outputDir = Platform.recordingsDir +/+ "GrainBuffers";


~grainsb = Bus.audio(s, 2);

~granulators = Array.new(4);
~posb = Array.new(4);
~rectriggerb = Array.new(4);
~possynths = Array.new(4);
~triggersynths = Array.new(4);

// create the control busses

(0..3).do({
	var ps;
	~posb.add(Bus.control(s, 1));
	~rectriggerb.add(Bus.control(s, 1));
});

// start the granulators

(0..3).do({ |i|
	var pb = ~posb[i], rtb = ~rectriggerb[i];
	~granulators.add(Granulator.new(~buflen, ~infxb, ~grainsb, pb, rtb));
});


// launch the pos synths and triggers to sync the buffer recorders

(0..3).do({ |i|
	var pb = ~posb[i], rtb = ~rectriggerb[i];
	~possynths.add(Synth(\pos_saw, [ \out, pb, \speed, 1 / ~buflen ]));
	~triggersynths.add(Synth(\trigger, [ \out, rtb ]));
});

// TODO - retrigger the buffer records when changing the length etc

~setmode = {
	arg track, mode;
	var synth = ~modes[mode][1];
	~possynths[track].get(\speed, { | speed |
		~possynths[track].free;
		~triggersynths[track].free;
		~possynths[track] = Synth(synth, [\out, ~posb[track], \speed, speed]);
		~triggersynths[track] = Synth(\trigger, [ \out, ~rectriggerb[track] ]);
	});
	~granulators[track].mode_(mode);
};

~dumpbuffers = { |prefix|
	(0..3).do({|i|
		var filename = ~outputDir +/+ prefix ++ 'buffer' ++ i.asString ++ '.aiff';
		~granulators[i].buffer.write(filename);
	});
}
)
