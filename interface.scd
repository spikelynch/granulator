
v = 1.0;

v.asInt

(
~to = TouchOSC("192.168.0.209", 9000);

~speeds = [ 1, 1, 1, 1 ];


OSCdef.freeAll;



~to.button('/reset', 0, { | v |
	if( v > 0, {
		var sp = ~to.v('/grains/speed')[0];
		~buflen = ~to.v('/grains/buflen');
		(0..3).do({|i|
			var speed = ~to.v('/grains/speed' ++ i);
			~granulators[i].reset(~buflen);
			~possynths[i].set(\speed, speed / ~buflen);
		});
	});
});


// when selecting a track, sets all the controls on the track page to this one

~to.button('/trackselect', 0, { |v|
	~tracknum = v.asInteger;
	~granulator = ~granulators[~tracknum];
	~to.v_('/track/record', ~granulator.record);
	~to.v_('/track/mode',   ~granulator.mode);
	~to.v_('/track/speed',  ~speeds[~tracknum]);

	~to.v_('/track/blur',   ~granulator.blur);
	~to.v_('/track/size',   ~granulator.size);
	~to.v_('/track/mix',    ~granulator.mix);
	~to.v_('/track/pan',    ~granulator.pan);
	~to.v_('/track/track',  ~granulator.track);
	~to.v_('/track/jitter',  ~granulator.jitter);
});


// note: ~buflen is the variable for buffer length, which only gets set to
// ~to.v('/grains/buflen') when the buffer is reset with the clear button

~to.slider('/grains/buflen', ~buflen, TouchOSCScale(0.1, 10.0), {});


~to.button('/grains/record0', 0, { | v | ~granulators[0].record_(v) });
~to.button('/grains/record1', 0, { | v | ~granulators[1].record_(v) });
~to.button('/grains/record2', 0, { | v | ~granulators[2].record_(v) });
~to.button('/grains/record3', 0, { | v | ~granulators[3].record_(v) });

~to.button('/grains/mode0', 0, { |v| ~setmode.value(0, v) });
~to.button('/grains/mode1', 0, { |v| ~setmode.value(1, v) });
~to.button('/grains/mode2', 0, { |v| ~setmode.value(2, v) });
~to.button('/grains/mode3', 0, { |v| ~setmode.value(3, v) });

~to.slider('/grains/speed0', 1, TouchOSCScale(0, 2), { |v| ~speeds[0] = v; ~possynths[0].set(\speed, v) });
~to.slider('/grains/speed1', 1, TouchOSCScale(0, 2), { |v| ~speeds[1] = v; ~possynths[1].set(\speed, v)
});
~to.slider('/grains/speed2', 1, TouchOSCScale(0, 2), { |v| ~speeds[2] = v; ~possynths[2].set(\speed, v) });
~to.slider('/grains/speed3', 1, TouchOSCScale(0, 2), { |v| ~speeds[3] = v; ~possynths[3].set(\speed, v) });

~to.slider('/grains/passthrough', 0.75, TouchOSCScale(0, 1), { |v| ~grainmixer.set(\passthrough, v) });

~to.slider('/grains/mix0',   0.5, TouchOSCScale(0, 1), { | v | ~granulators[0].gain_(v) });
~to.slider('/grains/mix1',   0.5, TouchOSCScale(0, 1),{ | v | ~granulators[1].gain_(v) });
~to.slider('/grains/mix2',   0.5, TouchOSCScale(0, 1),{ | v | ~granulators[2].gain_(v) });
~to.slider('/grains/mix3',   0.5, TouchOSCScale(0, 1),{ | v | ~granulators[3].gain_(v) });

~to.button('/grains/speedquant',   0, { |v| });

~to.slider('/grains/trigger', 120, TouchOSCScale(0, 640), { |v| ~trigger.set(\freq, v) });

~to.button('/grains/dust',   0,  { |v| ~trigger.set(\dust, v) });
~to.button('/grains/back',   0,  { |v| ~pitch.set(\dir, if( v > 0, { -1 }, { 1}))});
~to.button('/grains/slope',   1, { |v| ~pitch.set(\track, v) });

~to.button('/grains/chorus', 0, { |v| ~pitch.set(\chorus, v) });
~to.slider('/grains/detune', 0, TouchOSCScale(0, 0.059),  { |v| ~pitch.set(\detune, v) });
~to.slider('/grains/pitch', 0, TouchOSCScale(-2, 2),      { |v| ~pitch.set(\pitch, v.round) });


// Page 2: track

// these just set the value on the first page

~to.button('/track/record',  0, { | v | ~to.v_('grains/record' ++ ~tracknum, v) });
~to.button('/track/mode',    0, { | v | ~to.v_('grains/mode' ++ ~tracknum, v) });
~to.slider('/track/speed',   1, TouchOSCScale(0, 2), { |v| ~to.v_('grains/speed' ++ ~tracknum, v) });

// these set the values on the actual granulator

~to.slider('/track/blur',   0, TouchOSCScale(0, 0.25),    { |v| ~granulator.blur_(v) });
~to.slider('/track/size', 0.1, TouchOSCScale(0, 0.5),     { |v| ~granulator.size_(v) });

~to.slider('/track/mix',    0.25, TouchOSCScale(0, 1),    { |v| ~granulator.mix_(v); });
~to.slider('/track/pan',      0,    TouchOSCScale(-1, 1), { |v| ~granulator.pan_(v) });
~to.slider('/track/track',   0.5,  TouchOSCScale(-1, 1),  { |v| ~granulator.track_(v) });
~to.slider('/track/jitter', 0.25, TouchOSCScale(0, 1),    { |v| ~granulator.jitter_(v) });




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

