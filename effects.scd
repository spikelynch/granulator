
// this is just output effects now

(


~outfxb = Bus.audio(s, 2);
~delayb = Bus.audio(s, 2);
~reverbb = Bus.audio(s, 2);



~grainmixer = SynthDef(
	\grain_mixer,
	{
		arg in=2, grainb=4, out=0, passthrough=0.75, grains=1;
		Out.ar(out, (grains * In.ar(grainb, 2)) + (passthrough * In.ar(in, 1) ! 2));
	}
).play(s, [\in, ~infxb, \grainb, ~grainsb, \out, ~outfxb ], \addToTail);




// delay always passes through 100% of its input + amp % of the delay


~delay = SynthDef(
 	\delay, {
 		arg in, out, maxdelay=1, delaytime=0.2, decaytime=0.1, amp=0.5;
 		var sig = In.ar(in, 2), del;
 		del = CombC.ar(sig, maxdelay, delaytime, decaytime, amp);
		Out.ar(out, sig + del);
 	}
 ).play(s, [ \in, ~outfxb, \out, ~delayb ], \addToTail);

// try taking out the reverb because I think it causes noises

 ~reverb = SynthDef(
 	\reverb, {
 		arg in, out, mix=0.33, room=0.5, damp=0.5, amp=0.25;
 		var input = In.ar(in, 2);
 		Out.ar(out, input + FreeVerb2.ar(input[0], input[1], mix, room, damp, amp));
 	}
 ).play(s, [ \in, ~delayb, \out, 0 ], \addToTail);

"Effects running".postln;
)

