// Execute this before booting the server

(
Server.default.options.inDevice_("Scarlett 2i2 USB");
Server.default.options.outDevice_("Scarlett 2i2 USB");
)
Server.killAll;
~frippbuffer.write("/Users/mike/Music/SuperCollider Recordings/slow.aiff");


(

~to = TouchOSC("192.168.0.209", 9000);

~usbinput = 2;

~usbinput1 = 2;

~usbinput2 = 3;


~buflen = 4.0;
~beatsperbar = 4;

// trying setting the playback LFOs before the controls

// granulator playback modes
// each of these is a control bus with a synth that drives the pattern
// the granulator mode control switches between them

// more ideas for modules: scramble - do a permutation of ABCDEFGH slots

// todo - encapsulate these in a class


~grainsinb = Bus.control(s, 1);

~grainsin = SynthDef(
	\grainsin,
	{
		arg out=5, speed=1;
		Out.kr(out, 0.5 + SinOsc.kr(speed * 0.5, 0, 0.5));
	}
).play(s, [\out, ~grainsinb, \speed, 1]);

~grainsawb = Bus.control(s, 1);

~grainsaw = SynthDef(
	\grainsaw,
	{
		arg out=5, speed=1;
		Out.kr(out, 0.5 + LFSaw.kr(speed, 0, 0.5));
	}
).play(s, [\out, ~grainsawb, \speed, 1]);

~grainreverseb = Bus.control(s, 1);

~grainreverse = SynthDef(
	\grainreverse,
	{
		arg out=5, speed=1;
		Out.kr(out, 0.5 - LFSaw.kr(speed, 0, 0.5));
	}
).play(s, [\out, ~grainreverseb, \speed, 1]);

~graintrib = Bus.control(s, 1);

~graintri = SynthDef(
	\graintri,
	{
		arg out=5, speed=1;
		Out.kr(out, 0.5 + LFTri.kr(speed, 0, 0.5));
	}
).play(s, [\out, ~graintrib, \speed, 1]);


~grainstepb = Bus.control(s, 1);

~grainstep = SynthDef(
	\grainstep,
	{
		arg out=5, speed=1, steps=8;
		var stepwise = LFSaw.kr(speed, 0.0, 0.5 * steps, 0.5 * steps).floor;
		Out.kr(out, stepwise / steps);
	}
).play(s, [\out, ~grainstepb, \speed, 1]);


~grainrandb = Bus.control(s, 1);

~grainrand = SynthDef(
	\grainrand,
	{
		arg out=5, speed=1;
		Out.kr(out, 0.5 + WhiteNoise.kr(0.5));
	}
).play(s, [\out, ~grainrandb, \speed, 1]);


~modes = [
	[ ~grainsaw, ~grainsawb, "saw" ],
	[ ~grainreverse, ~grainreverseb, "reverse", ],
	[ ~grainsin, ~grainsinb, "sine" ],
	[ ~grainstep, ~grainstepb, "step" ],
	[ ~grainrand, ~grainrandb, "random" ]
];

~playbacklfo = ~modes[0][0];
~playbacklfob = ~modes[0][1];
// audio buses

// recordb = input to bufrecorder


~recordb = Bus.audio(s, 1);

// ~infilter = SynthDef(
// 	\input_null,
// 	{
// 		arg in = 2, out = 4;
// 		Out.ar(out, In.ar(in));
// 	}
// ).play(s, [\in, ~usbinput, \out, ~recordb]);

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


fork {
	SynthDef(
		\lfo,
		{
			arg out=5, freq=1, amp=0;
			Out.kr(out, SinOsc.kr(freq, 0, amp));
		}
	).add;

	1.wait;

	~lfoa = Synth(\lfo, [\out, ~lfoab ]);
	~lfob = Synth(\lfo, [\out, ~lfobb ]);
	~lfoc = Synth(\lfo, [\out, ~lfocb ]);
	"LFOs initialised".postln;
};




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
		arg out, posb, triggerb, track=1, dir=1, detune=0.0, chorus=0, harmonics=2, pitch=0, quant=1;
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


// pitch gets quantised to octaves from 3 below to 3 above.
// NOTE: the pitch TouchOSC control is -1 to 1, not 0 to 1
// min/max gets ignored because I'm overloading the ctrlset/get

// TODO: fixme,

// ~to.slider('/grainfx/pitch', -1, 1, 1,
// 	{ |self| ~granulator.set("rate", self.v) },

// 	{ |self, ctrlv | self.v = 2.pow((ctrlv * 3).floor) },
// 	{ |self|         self.v.log2.floor / 3; }
// );



// buffer recorder

~frippbuffer = Buffer.alloc(s, s.sampleRate * ~buflen, 1);

~bufrecorder = SynthDef(
	\fripp_record,
	{
		arg in = 2, fb = 4, buffer = 0, mix = 0.25, record = 0.0, feedback = 0.0;
		var insig, fbsig;
		insig = record * In.ar(in, 1);
		fbsig = feedback * Mix.ar(In.ar(fb, 2));
		RecordBuf.ar(insig + fbsig, buffer, 0, mix, 1 - mix, loop: 1)
    }
).play(s, [\in, ~recordb, \record, 1.0, \fb, ~granulatorb, \out, 0, \buffer, ~frippbuffer], \addToTail);


// the main granulator synth


~granulator = SynthDef(
	\grainsynth,
	{
		arg out=0, buffer, pitchb, triggerb, posb, modb, size=0.1, amp=1.0, pan=0, track=0.25, jitter=0, blur=0.0;
		var pitch, blen, trigger, chor, pos, pans, grains, filtfreq;
		//trigger = Impulse.kr(120);
		trigger = In.kr(triggerb);
		pitch = In.kr(pitchb);
		blen = BufDur.kr(buffer);
		pos = Wrap.kr(In.kr(posb, 1) + WhiteNoise.kr(blur), 0, 1);
		pans = pan + WhiteNoise.kr(jitter) + (track * (In.kr(posb, 1) - 1));
		grains = TGrains.ar(2, trigger, buffer, pitch, pos * blen, size, pans, amp);
		Out.ar(out, grains);
	}
).play(s, [
	\out, ~granulatorb,
	\buffer, ~frippbuffer,
	\posb, ~playbacklfob,
	\triggerb, ~triggerb,
	\pitchb, ~pitchb,
	\modb, ~lfob,
	\size, 0.1
]);

// mixing and effects

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




(


OSCdef.freeAll;

~to.button('/record', 1, { | v | ~bufrecorder.set(\record, v) });


~to.button('/reset', 0, { | v |
	if( v > 0, {
		var sp = ~to.v('/grains/speed')[0];
		~buflen = ~to.v('/grains/buflen');
		[ "resetting buffer to", ~buflen ].postln;
		~newbuffer = Buffer.alloc(s, s.sampleRate * ~buflen, 1);
		~granulator.set(\buffer, ~newbuffer);
		~bufrecorder.set(\buffer, ~newbuffer);
		if( ~frippbuffer.isNil.not, { ~frippbuffer.free });
		~frippbuffer = ~newbuffer;
		~playbacklfo.set(\speed, sp / ~buflen);
	});
});


~to.slider('/mix', 0.25, TouchOSCScale(0, 1),        { |v| ~bufrecorder.set(\mix, v) } );
~to.slider('/gain', 0.5, TouchOSCScale(0, 1),    { |v| ~granulator.set(\amp, v) } );
~to.slider('/passthrough', 0.75, TouchOSCScale(0, 1), { |v| ~grainmixer.set(\passthrough, v) } );

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
		~granulator.set(\posb, mode[1]);
		~playbacklfo = mode[0];
		~playbacklfob = mode[1];
		~playbacklfo.set(\speed, ~to.v('/grains/speed')[0] / ~buflen);
	}, {
		[ "Bad mode index", v ].postln;
	});
});

~to.button('/grains/dust',   0, { |v| ~trigger.set(\dust, v) });
~to.slider('/grains/blur',   0, TouchOSCScale(0, 1), { |v| ~granulator.set(\blur, v) });


// todo vvv quantise speed should be swappable

// var trate, qspeed;
// qspeed = 2.pow(v[0].floor);
// ~playbacklfo.set(\speed, qspeed / ~buflen);
// [ "speed", v[0], qspeed, qspeed / ~buflen ].postln;
// trate = 2.pow(v[1].floor) / ~buflen;
// ~granulator.set(\trate, trate);



~to.slider('/grains/size', 0.1, TouchOSCScale(0, 0.5),{
	|v| ~granulator.set(\size, v)
});

// Page 2: grainfx

~to.button('/grainfx/back',   0, { |v| ~pitch.set(\dir, if( v > 0, { -1 }, { 1}))});

~to.button('/grainfx/slope',   1, { |v| ~pitch.set(\track, v) });


~to.slider('/grainfx/pan', 0,    TouchOSCScale(-1, 1), { |v| ~granulator.set(\pan, v) });
~to.slider('/grainfx/track', 0.5,  TouchOSCScale(-1, 1), { |v| ~granulator.set(\track, v) });
~to.slider('/grainfx/jitter', 0.25, TouchOSCScale(0, 1), { |v| ~granulator.set(\jitter, v) });


~to.button('/grainfx/chorus', 0, { |v| ~pitch.set(\chorus, v) });

~to.slider('/grainfx/detune', 0, TouchOSCScale(0, 0.059),  { |v| ~pitch.set(\detune, v) });

~to.slider('/grainfx/pitch', 0, TouchOSCScale(-2, 2),      { |v| ~pitch.set(\pitch, v.round) });

~to.button('/grainfx/quant', 1, { |v|
	~pitch.set(\quant, v);
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

~posdisplay.stop;

~pitch.set(\harmonics, 1.5);

~pitchb.scope

~trigger.set(\dust,0);

(
~testpitchb = Bus.control(s, 1);

~test = SynthDef(
	\testpitch,
	{
		arg out, triggerb;
		var csig, dsig, chor;
		csig = Latch.kr(WhiteNoise.kr(), In.kr(triggerb));
		//dsig = Latch.kr(WhiteNoise.kr(), In.kr(triggerb));
		chor = 2.pow((csig * 2).round);
		Out.kr(out, chor);
	}
).play(s, [ \out, ~testpitchb, \triggerb, ~triggerb ]);
)

~test.free

2.pow(3)
-2.49.round

0.4.asFraction(3)

(
~trig2 = SynthDef(
    \trig2,
	{
		arg out, freq=1, dust=0;
		Out.kr(out, Impulse.kr(freq) * (1 - dust)) + (Dust.kr(freq) * dust);
}
).play(s, [ \out, ~triggerb, \freq, 120, \dust, 0 ]);


~frippbuffer.write("/Users/mike/Music/SuperCollider Recordings/slow.aiff");

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

// s.sync(); // this needs to be done in a routine because it calls yield
// sidebar -

