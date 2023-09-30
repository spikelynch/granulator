

(
~to = TouchOSC("192.168.0.209", 9000);


~tracknum = 0;
~granulator = ~granulators[0];

~speedlock = 0;
~speedquant = 0;

OSCdef.freeAll;


~to.button('/grains/reset', 0, { | v |
	if( v > 0, {
		~buflen = ~to.v('/grains/buflen');
		(0..3).do({|i|
			~granulators[i].reset(~buflen);
		});
	});
});

~quantspeed = { |v| 2.pow((v * 4 + 0.5).round - 5) };

// control ganging is hella laggy, do it in TouchOSC


~setspeed = { | track, v |
	var speed, qv = if(~speedquant > 0, { ~quantspeed.value(v) }, { v });
	speed = qv / ~buflen;
	if(~speedlock > 0, {
		(0..3).do({|n|
			~possynths[n].set(\speed, speed);
			if( n != track, {
				var url = ("/grains/speed" ++ n).asSymbol;
				~to.s_(url, v);
			});
		});
	},
	{ ~possynths[track].set(\speed, speed) });
};

// setrecord: toggles record on (1) or off (0) for a track, and also sets the
// track's input mix to 0 so that it doesn't start fadeing out. If the track
// is the currently selected track, set its touchosc control to 0.
// keeps the level for each track in an array and resets it

~mixlevel = Array.new(4);

(0..3).do({~mixlevel.add(0.25)});


~setrecord = { | track, v |
	~granulators[track].record_(v);
	if(v == 0, {
		~mixlevel[track] = ~granulators[track].mix;
		~granulators[track].mix_(0);
	},
	{
		~granulators[track].mix_(~mixlevel[track]);
	});
	if( track == ~tracknum, { ~to.v_('/track/mix', ~granulators[track].mix); })
};



// note: ~buflen is the variable for buffer length, which only gets set to
// ~to.v('/grains/buflen') when the buffer is reset with the clear button

~to.slider('/grains/buflen', ~buflen, TouchOSCScale(0.1, 10.0), {});




~to.button('/grains/record0', 0, { | v | ~setrecord.value(0, v) });
~to.button('/grains/record1', 0, { | v | ~setrecord.value(1, v) });
~to.button('/grains/record2', 0, { | v | ~setrecord.value(2, v) });
~to.button('/grains/record3', 0, { | v | ~setrecord.value(3, v) });



~to.button('/grains/mode0', 0, { |v| ~granulators[0].mode_(v); ~setmode.value(0, v) });
~to.button('/grains/mode1', 0, { |v| ~granulators[1].mode_(v); ~setmode.value(1, v) });
~to.button('/grains/mode2', 0, { |v| ~granulators[2].mode_(v); ~setmode.value(2, v) });
~to.button('/grains/mode3', 0, { |v| ~granulators[3].mode_(v); ~setmode.value(3, v) });

~to.slider('/grains/speed0', 1, TouchOSCScale(0, 2), { |v| ~setspeed.value(0, v) });
~to.slider('/grains/speed1', 1, TouchOSCScale(0, 2), { |v| ~setspeed.value(1, v) });
~to.slider('/grains/speed2', 1, TouchOSCScale(0, 2), { |v| ~setspeed.value(2, v) });
~to.slider('/grains/speed3', 1, TouchOSCScale(0, 2), { |v| ~setspeed.value(3, v) });


~to.slider('/grains/passthrough', 0.75, TouchOSCScale(0, 1), { |v| ~grainmixer.set(\passthrough, v) });

~to.slider('/grains/mix0',   0.5, TouchOSCScale(0, 1), { | v | ~granulators[0].gain_(v) });
~to.slider('/grains/mix1',   0.5, TouchOSCScale(0, 1),{ | v | ~granulators[1].gain_(v) });
~to.slider('/grains/mix2',   0.5, TouchOSCScale(0, 1),{ | v | ~granulators[2].gain_(v) });
~to.slider('/grains/mix3',   0.5, TouchOSCScale(0, 1),{ | v | ~granulators[3].gain_(v) });

~to.button('/grains/lock',   0, { |v| ~speedlock = v });

~to.button('/grains/quant',   0, { |v| ~speedquant = v });


// Page 2: track


~to.xy('/track/triggersize', [ 100, 0.125 ], TouchOSCScale(0, 200), TouchOSCScale(0, 0.25), { |v|
	~granulator.trigger_(v[0]);
	~granulator.size_(v[1]);
});

~to.slider('/track/blur',   0, TouchOSCScale(0, 0.25),    { |v| ~granulator.blur_(v) });

~to.button('/track/dust',   0,                           { |v| ~granulator.dust_(v) });
~to.button('/track/back',   0,                           { |v| ~granulator.back_(v)});
~to.button('/track/slope',   0,                          { |v| ~granulator.slope_(v) });

~to.button('/track/chorus', 0,                            { |v| ~granulator.chorus_(v) });
~to.slider('/track/detune', 0, TouchOSCScale(0, 0.059),   { |v| ~granulator.detune_(v) });
~to.slider('/track/pitch', 0, TouchOSCScale(-2, 2),       { |v| ~granulator.pitch_(v.round) });

~to.slider('/track/mix',    0.25, TouchOSCScale(0, 1),    { |v| ~granulator.mix_(v); });
~to.slider('/track/pan',      0,    TouchOSCScale(-1, 1), { |v| ~granulator.pan_(v) });
~to.slider('/track/track',   0.5,  TouchOSCScale(-1, 1),  { |v| ~granulator.track_(v) });
~to.slider('/track/jitter', 0.25, TouchOSCScale(0, 1),    { |v| ~granulator.jitter_(v) });



~to.button('/trackselect', 0, { |v|
 	~tracknum = v.asInteger;
 	~granulator = ~granulators[~tracknum];

	~to.v_('/track/triggersize', [~granulator.trigger, ~granulator.size]);
 	~to.v_('/track/blur',   ~granulator.blur);
	~to.v_('/track/mix',    ~granulator.mix);
 	~to.v_('/track/pan',    ~granulator.pan);
 	~to.v_('/track/track',  ~granulator.track);
 	~to.v_('/track/jitter', ~granulator.jitter);
 	~to.v_('/track/dust',   ~granulator.dust);
 	~to.v_('/track/slope',  ~granulator.slope);
 	~to.v_('/track/back',   ~granulator.back);
 	~to.v_('/track/chorus', ~granulator.chorus);
 	~to.v_('/track/detune', ~granulator.detune);
 	~to.v_('/track/pitch',  ~granulator.pitch);
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

