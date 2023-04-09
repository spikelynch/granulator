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
	[ "random", \pos_random ]
];

~granulators = Array.new(4);
~posb = Array.new(4);
~possynths = Array.new(4);

(0..3).do({
	var pb = Bus.control(s, 1), ps;
	~posb.add(pb);
	ps = Synth(\pos_saw, [ \out, pb ]);
	~possynths.add(ps);
});


(0..3).do({ |i|
	var pb = ~posb.at(i);
	~granulators.add(Granulator.new(~buflen, ~recordb, ~outb, pb, ~triggerb, ~pitchb));
});

)

(
~setmode = {
	arg track, mode;
	var synth = ~modes[mode][1];
	~possynths[track].get(\speed, { | speed |

		~possynths[track].free;
		~possynths[track] = Synth(synth, [\out, ~posb[track], \speed, speed]);
	});
}
)

~granulators[0].gain(1);

("./interface.scd").loadRelative;









