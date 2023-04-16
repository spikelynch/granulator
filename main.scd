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
	ps = Synth(\pos_saw, [ \out, pb, \speed, 1 / ~buflen ]);
	~possynths.add(ps);
});


(0..3).do({ |i|
	var pb = ~posb.at(i);
	~granulators.add(Granulator.new(~buflen, ~recordb, ~fxb, pb, ~triggerb, ~pitchb));
});

~setmode = {
	arg track, mode;
	var synth = ~modes[mode][1];
	~possynths[track].get(\speed, { | speed |
		~possynths[track].free;
		~possynths[track] = Synth(synth, [\out, ~posb[track], \speed, speed]);
	});
	~granulators[track].mode_(mode);
}
)


("./interface.scd").loadRelative;

~to.controls.keys.do({|k, i| i.postln; k.postln;~to.controls[k].postln});
~to.controls['/track/speed'].send_(0.1);
~to.v_(, 0);

~to.controls.at(~trackctrl.value('speed')).isNil.not

a = "string"
b = 'string'

a.asSymbol



~possynths[0].get(\speed, {|v| v.postln});
~possynths[0].set(\speed, 20 / ~buflen)