(
~to = TouchOSC("192.168.0.209", 9000);


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

