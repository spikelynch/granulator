
(
// audio buses and other control stuff

// recordb = input to bufrecorder


~recordb = Bus.audio(s, 1);

~inmixer = SynthDef(
	\input_null,
	{
		arg in1 = 2, in2 = 3, out = 4;
		Out.ar(out, In.ar(in1) + In.ar(in2));
	}
).play(s, [\in1, ~usbinput1, \in2, ~usbinput2, \out, ~recordb]);

~grb = Bus.audio(s, 2);

// LFO buses and synths

~lfoab = Bus.control(s, 1);
~lfobb = Bus.control(s, 1);
~lfocb = Bus.control(s, 1);

~lfoa = Synth(\lfo, [\out, ~lfoab ]);
~lfob = Synth(\lfo, [\out, ~lfobb ]);
~lfoc = Synth(\lfo, [\out, ~lfocb ]);

"LFOs running".postln;

)
