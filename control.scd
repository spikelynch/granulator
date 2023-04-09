
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

// a kr synth which triggers grains

~triggerb = Bus.control(s, 1);

~trigger = SynthDef(
    \trigger,
	{
		arg out, freq=1, dust=0;
		Out.kr(out, (Impulse.kr(freq) * (1 - dust)) + (Dust.kr(freq) * dust));
}
).play(s, [ \out, ~triggerb, \freq, 120, \dust, 0 ]);



// a kr synth which is used to control the granulator
// playback rate.

~pitchb = Bus.control(s, 1);

~pitch = SynthDef(
	\pitch,
	{
		arg out, posb, triggerb, track=1, dir=1, detune=0.0, chorus=0, harmonics=2, pitch=0;
		var tracking, base, chor, det, csig, dsig;
		csig = Latch.kr(WhiteNoise.kr(), In.kr(triggerb));
		dsig = Latch.kr(WhiteNoise.kr(), In.kr(triggerb));
		tracking = Schmidt.kr(Slope.kr(posb), 0, 0) * 2 - 1;
		base = 2.pow(pitch) * dir * (track * tracking + (1 - track));
		det = detune * dsig + 1;
		chor = chorus * harmonics.pow((csig * 2).round) + (1 - chorus);
		Out.kr(out, base * chor * det);
	}
).play(s, [ \out, ~pitchb, \triggerb, ~triggerb, \posb, ~playbacklfob, \dir, 1, \track, 0]);

)
