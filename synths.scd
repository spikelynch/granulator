(

~usbinput = 2;
~usbinput1 = 2;
~usbinput2 = 3;

~buflen = 4.0;
~beatsperbar = 4;

SynthDef(\pos_sine, {
	arg out, speed=1;
	Out.kr(out, 0.5 + SinOsc.kr(speed * 0.5, 0, 0.5));
}).add;

SynthDef(\pos_saw, {
	arg out, speed=1;
	Out.kr(out, 0.5 + LFSaw.kr(speed, 0, 0.5, 0.5));
}).add;

SynthDef(\pos_reverse, {
	arg out, speed=1;
	Out.kr(out, 0.5 - LFSaw.kr(speed, 0, 0.5, 0.5));
}).add;

SynthDef(\pos_step, {
	arg out, speed=1, steps=8;
	var stepwise = LFSaw.kr(speed, 0.0, 0.5 * steps, 0.5 * steps).floor;
	Out.kr(out, stepwise / steps);
}).add;

SynthDef(\pos_random, {
	arg out=5, speed=1;
	Out.kr(out, 0.5 + WhiteNoise.kr(0.5));
}).add;

SynthDef(\lfo, {
	arg out, freq=1, amp=0;
	Out.kr(out, SinOsc.kr(freq, 0, amp));
}).add;

SynthDef(\trigger, {
	arg out=1;
	Out.kr(out, Impulse.kr(0))
}).add;


)
