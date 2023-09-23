
(

//input mixing, effects and lfos

~inputb = Bus.audio(s, 1);
~infxb = Bus.audio(s, 1);

~inmixer = SynthDef(
	\input_null,
	{
		arg in1 = 2, in2 = 3, out = 4;
		Out.ar(out, In.ar(in1) + In.ar(in2));
	}
).play(s, [\in1, ~usbinput1, \in2, ~usbinput2, \out, ~inputb]);


// LFO buses and synths

~lfoab = Bus.control(s, 1);
~lfobb = Bus.control(s, 1);
~lfocb = Bus.control(s, 1);

~lfoa = Synth(\lfo, [\out, ~lfoab ]);
~lfob = Synth(\lfo, [\out, ~lfobb ]);
~lfoc = Synth(\lfo, [\out, ~lfocb ]);

"LFOs running".postln;

// filter is now before grains

~filtermodb = Bus.control(s, 1);

~filtermod = SynthDef(
	\filtermod, {
		arg out, a = 1.0, b = 0.0, c = 0.0;
		var siga, sigb, sigc;
		siga = In.kr(~lfoab) * a;
		sigb = In.kr(~lfobb) * b;
		sigc = In.kr(~lfocb) * c;
		Out.kr(out, Wrap.kr(siga + sigb + sigc, -1, 1));
	}
).play(s, [\out, ~filtermodb, \a, 1, \b, 0, \c, 0 ]);


~filter = SynthDef(
	\filter, {
		arg in, out, mod, freq=10000, res=0.3, amp=1.0;
		var filt, lfo;
		lfo = LinExp.kr(In.kr(mod, 1), -1, 1, freq * 0.5, freq * 2);
		filt = RLPF.ar(In.ar(in, 2) * amp, lfo, res);
		Out.ar(out, filt);
	}
).play(s, [ \in, ~inputb, \out, ~infxb, \mod, ~filtermodb, \amp, 0.5], \addToTail);


)
