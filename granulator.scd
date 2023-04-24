
(
~modes = [
	[ "saw", \pos_saw ],
	[ "reverse", \pos_reverse ],
	[ "sine", \pos_sine ],
	[ "step", \pos_step ],
	[ "random", \pos_random ]
];

~grainsb = Bus.audio(s, 2);

~granulators = Array.new(4);
~posb = Array.new(4);
~possynths = Array.new(4);

(0..3).do({
	var pb = Bus.control(s, 1), ps;
	~posb.add(pb);
	ps = Synth(\pos_saw, [ \out, pb, \speed, 1 / ~buflen ]);
	~possynths.add(ps);
});


(0..3).do({ |i|
	var pb = ~posb.at(i);
	~granulators.add(Granulator.new(~buflen, ~infxb, ~grainsb, pb, ~triggerb, ~pitchb));
});

~setmode = {
	arg track, mode;
	var synth = ~modes[mode][1];
	~possynths[track].get(\speed, { | speed |
		~possynths[track].free;
		~possynths[track] = Synth(synth, [\out, ~posb[track], \speed, speed]);
	});
	~granulators[track].mode_(mode);
};

"Granulator running".postln;

)

