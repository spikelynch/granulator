// Execute this before booting the server

(
Server.default.options.inDevice_("Scarlett 2i2 USB");
//Server.default.options.outDevice_("Scarlett 2i2 USB");
)
Server.killAll;
~frippbuffer.write("/Users/mike/Music/SuperCollider Recordings/slow.aiff");
~frippbuffer.isNil;


(
~to = TouchOSC("192.168.0.209", 9000);

~usbinput = 2;
~usbinput1 = 2;
~usbinput2 = 3;

~buflen = 4.0;
~beatsperbar = 4;

~posb0 = Bus.control(s, 1);
~posb1 = Bus.control(s, 1);
~posb2 = Bus.control(s, 1);
~posb3 = Bus.control(s, 1);

SynthDef(\pos_sin, {
	arg out, speed=1;
	Out.kr(out, 0.5 + SinOsc.kr(speed * 0.5, 0, 0.5));
}).add;

SynthDef(\pos_saw, {
	arg out, speed=1;
	Out.kr(out, 0.5 + LFSaw.kr(speed, 0, 0.5));
}).add;

SynthDef(\pos_reverse, {
	arg out, speed=1;
	Out.kr(out, 0.5 - LFSaw.kr(speed, 0, 0.5));
}).add;

SynthDef(\pos_step, {
	arg out, speed=1, steps=8;
	var stepwise = LFSaw.kr(speed, 0.0, 0.5 * steps, 0.5 * steps).floor;
	Out.kr(out, stepwise / steps);
}).add;

SynthDef(\pos_rand, {
	arg out=5, speed=1;
	Out.kr(out, 0.5 + WhiteNoise.kr(0.5));
}).add;

SynthDef( \lfo, {
	arg out, freq=1, amp=0;
	Out.kr(out, SinOsc.kr(freq, 0, amp));
}).add;

)

~modes = [
	[ "saw", \pos_saw ],
	[ "reverse", \pos_reverse ],
	[ "sine", \pos_sine ],
	[ "step", \pos_step ],
	[ "random", \pos_rand ]
];


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

~granulatorb = Bus.audio(s, 2);

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

Granulator.init(s)

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



(


OSCdef.freeAll;

~to.button('/record', 1, { | v | ~bufrecorder.set(\record, v) });


~to.button('/reset', 0, { | v |
	if( v > 0, {
		var sp = ~to.v('/grains/speed')[0];
		~buflen = ~to.v('/grains/buflen');
		~granulators.do({|g, i| g.reset(~buflen) }
		~playbacklfo.set(\speed, sp / ~buflen);
	});
});


~to.button('/track', 0, { |v|
	var buffer = ~frippbuffers[v];
	if( buffer.isNil.not, {
		[ "set track to", v, buffer ].postln;
		~bufrecorder.set(\record, 0.0);
		~bufrecorder.set(\mix, 0.0); // stop unselected track fading out
		~bufrecorder = ~bufrecorders[v];
		~bufrecorder.set(\record, ~to.v('/record'));
		~granulator = ~granulators[v];
		~to.v_('/grainfx/mix', 0); // will always be 0 because we turned it off
		// ~granulator.get(\amp, { | v | ~to.v_('/grainfx/gain', v) });
		// ~granulator.get(\blur, { | v | ~to.v_('/grains/blur', v) });
		// ~granulator.get(\size, { | v | ~to.v_('/grains/size', v) });
		// ~granulator.get(\pan, { | v | ~to.v_('/grainfx/pan', v) });
		// ~granulator.get(\track, { | v | ~to.v_('/grainfx/track', v) });
		// ~granulator.get(\jitter, { | v | ~to.v_('/grainfx/jitter', v) });
		// todo - set the grainmode based on what this one has
	}, {
		[ "Bad track index", v ].postln;
	});
});



~to.slider('/feedback',  0, TouchOSCScale(0, 0.25), { |v|
	~bufrecorder.set(\feedback, v) } );

~to.button('/grains/bpm', "~", {});

~tapper = TapBeats();

~to.button('/grains/tap', 0, { | v, t |
	if( v > 0, {
		~tapper.tap(t);
		if( ~tapper.bpm.isNil.not, {
			~to.v_('/grains/bpm', ~tapper.bpm.round(1));
		})
	})
});


~to.button('/grains/bpmsend', 0, { | v |
	if( ~tapper.bpm.isNil.not, {
		var bl = ~beatsperbar * ~tapper.bpm;
		~to.v_('/grains/buflen', bl);
		~to.v_('/reset', 1);
	});
});

// note: ~buflen is the variable for buffer length, which only gets set to
// ~to.v('/grains/buflen') when the buffer is reset with the clear button

~to.slider('/grains/buflen', ~buflen, TouchOSCScale(0.1, 10.0), {});


// this is a write-only control to display where the buffer playback is at

~to.slider('/grains/buffer', 0, TouchOSCScale(0, 1), {});

~to.xy('/grains/speed', [ 1, 120 ], TouchOSCScale(0, 2), TouchOSCScale(0, 640), { | v |
	~playbacklfo.set(\speed, v[0] / ~buflen);
	~trigger.set(\freq, v[1]);
});

~to.button('/grains/mode', 0, { |v|
	var mode = ~modes[v];
	if( mode.isNil.not, {
		[ "granulator is", ~granulator ].postln;
		~granulator.posb_(mode[1]);
		~playbacklfo = mode[0];
		~playbacklfob = mode[1];
		~playbacklfo.set(\speed, ~to.v('/grains/speed')[0] / ~buflen);
	}, {
		[ "Bad mode index", v ].postln;
	});
});

~to.button('/grains/speedquant',   0, { |v|
});

~to.slider('/grains/step', 4, TouchOSCScale(1, 8), { |v|
	~grainstep.set(\steps, v.floor);
});



~to.button('/grains/dust',   0, { |v| ~trigger.set(\dust, v) });
~to.slider('/grains/blur',   0, TouchOSCScale(0, 0.25), { |v| ~granulator.blur_(v) });
~to.slider('/grains/size', 0.1, TouchOSCScale(0, 0.5),{ |v| ~granulator.size_(v) });

// Page 2: grainfx

~to.slider('/grainfx/mix', 0.25, TouchOSCScale(0, 1), { |v| ~granulator.mix_(v);
});
~to.slider('/grainfx/gain', 0.5, TouchOSCScale(0, 1), { |v| ~granulator.gain_(v) } );
~to.slider('/grainfx/pt', 0.75, TouchOSCScale(0, 1), { |v| ~grainmixer.set(\passthrough, v) } );

~to.button('/grainfx/back',   0, { |v| ~pitch.set(\dir, if( v > 0, { -1 }, { 1}))});
~to.button('/grainfx/slope',   1, { |v| ~pitch.set(\track, v) });
~to.slider('/grainfx/pan', 0,    TouchOSCScale(-1, 1), { |v| ~granulator.pan_(v) });
~to.slider('/grainfx/track', 0.5,  TouchOSCScale(-1, 1), { |v| ~granulator.track_(v) });
~to.slider('/grainfx/jitter', 0.25, TouchOSCScale(0, 1), { |v| ~granulator.jitter_(v) });


~to.button('/grainfx/chorus', 0, { |v| ~pitch.set(\chorus, v) });
~to.slider('/grainfx/detune', 0, TouchOSCScale(0, 0.059),  { |v| ~pitch.set(\detune, v) });
~to.slider('/grainfx/pitch', 0, TouchOSCScale(-2, 2),      { |v| ~pitch.set(\pitch, v.round) });

~to.button('/grainfx/quant', 1, { |v|
	// ~pitch.set(\quant, v);
	// just re-call the value setter for harmonics when toggled
	~to.v_('/grainfx/harmonics', ~to.v('/grainfx/harmonics'));
});

~to.slider('/grainfx/harmonics', 2, TouchOSCScale(0.1, 4),  { |v|
	if(~to.v('/grainfx/quant') > 0, {
		~pitch.set(\harmonics, v.round);
	},
	{
		~pitch.set(\harmonics, v);
	});
});


~to.slider(
	'/fx/filterfreq',
	10000, TouchOSCScaleExp(100, 10000), { |v| ~filter.set(\freq, v) }
);

~to.slider('/fx/grainmix',  1.0, TouchOSCScale(0, 1),   { |v| ~grainmixer.set(\grains, v) } );


~to.slider('/fx/filtermix',  0.8, TouchOSCScale(0, 1),   { |v| ~filter.set(\amp, v) } );

~to.button('/fx/filtermoda', 1, { |v| ~filtermod.set(\a, v) });
~to.button('/fx/filtermodb', 0, { |v| ~filtermod.set(\b, v) });
~to.button('/fx/filtermodc', 0, { |v| ~filtermod.set(\c, v) });


~to.slider('/fx/delay',  0.2,TouchOSCScale(0, 1),   { |v| ~delay.set(\delaytime, v) } );
~to.slider('/fx/decay',  1,  TouchOSCScale(0, 5),   { |v| ~delay.set(\decaytime, v) } );

~to.slider('/fx/delaymix',   0.2, TouchOSCScale(0, 1),   { |v| ~delay.set(\amp, v) } );


~to.slider('/fx/reverbwet',  0.33,TouchOSCScale(0, 1),   { |v| ~reverb.set(\mix, v) } );
~to.slider('/fx/reverbroom',  0.5,TouchOSCScale(0, 1),   { |v| ~reverb.set(\room, v) } );
~to.slider('/fx/reverbdamp',  0.5,TouchOSCScale(0, 1),   { |v| ~reverb.set(\damp, v) } );

~to.slider('/fx/reverbmix',  0.2, TouchOSCScale(0, 1),   { |v| ~reverb.set(\amp, v) } );



// note - the three LFOs have different rate ranges

~to.slider('/lfos/afreq',  0.5,TouchOSCScale(0.001, 2),   { |v| ~lfoa.set(\freq, v) } );
~to.slider('/lfos/aamp',  0,   TouchOSCScale(0, 1),       { |v| ~lfoa.set(\amp, v) });

~to.slider('/lfos/bfreq',  0.5,TouchOSCScale(0.01, 20),   { |v| ~lfob.set(\freq, v) } );
~to.slider('/lfos/bamp',  0,   TouchOSCScale(0, 1),       { |v| ~lfob.set(\amp, v) });

~to.slider('/lfos/cfreq',  0.5,TouchOSCScale(0.1, 200),   { |v| ~lfoc.set(\freq, v) } );
~to.slider('/lfos/camp',  0,   TouchOSCScale(0, 1),       { |v| ~lfoc.set(\amp, v) });


)

// old, slow buffer position display - to-do- this would be better in a GUI element
// on the laptop

(

~posdisplay = Task.new({
	{
		~playbacklfob.get({ | v |
			~to.v_('/grains/buffer', v)
		});
		0.02.wait;
	}.loop;
});


~posdisplay.start;
)



~frippbuffers[~currentfripp].write("/Users/mike/Music/SuperCollider Recordings/test.aiff");

(
~monitor = SynthDef(
	\monitor_synth,
	{
		arg in=2, out=0;
		Out.ar(out, In.ar(in, 2))
	}
).play(s, [\in, ~fxb, \out, 0 ], \addToTail);

)

~monitor.set(\in, ~reverbb)

~monitor.free

~pitchb.scope()

~frippbuffers.plot;

~bufrecorder.set(\buffer, ~frippbuffers[1]);


~granulators[0].get(\buffer, {|v| v.postln});

(
~frippbuffers.do({
	|b, i|
	b.write("/Users/mike/Music/SuperCollider Recordings/buffer" ++ i.asString ++ ".aiff");
});
)
