

(
// output effects mixing and effects

~fxb = Bus.audio(s, 2);
~filterb = Bus.audio(s, 2);
~grainsb = Bus.audio(s, 2);
~delayb = Bus.audio(s, 2);
~reverbb = Bus.audio(s, 2);



~grainmixer = SynthDef(
	\grain_mixer,
	{
		arg in=2, gbus=4, out=0, passthrough=0.75, grains=0.75;
		Out.ar(out, (grains * In.ar(gbus, 2)) + (passthrough * In.ar(~recordb, 1) ! 2));
	}
).play(s, [\in, ~usbinput, \gbus, ~granulatorb, \out, ~fxb ], \addToTail);

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
).play(s, [ \in, ~fxb, \out, ~filterb, \mod, ~filtermodb, \amp, 0.5 ], \addToTail);






// delay always passes through 100% of its input + amp % of the delay


~delay = SynthDef(
 	\delay, {
 		arg in, out, maxdelay=1, delaytime=0.2, decaytime=0.1, amp=0.5;
 		var sig = In.ar(in, 2), del;
 		del = CombC.ar(sig, maxdelay, delaytime, decaytime, amp);
		Out.ar(out, sig + del);
 	}
 ).play(s, [ \in, ~filterb, \out, ~delayb ], \addToTail);

// try taking out the reverb because I think it causes noises

 ~reverb = SynthDef(
 	\reverb, {
 		arg in, out, mix=0.33, room=0.5, damp=0.5, amp=0.25;
 		var input = In.ar(in, 2);
 		Out.ar(out, input + FreeVerb2.ar(input[0], input[1], mix, room, damp, amp));
 	}
 ).play(s, [ \in, ~delayb, \out, 0 ], \addToTail);

)
