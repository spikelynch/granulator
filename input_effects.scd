(

~fuzzbox = SynthDef(
	\fuzzbox,
	{
		arg in=2, out=4, distort=0.1, decay=0.999;
		var raw, cross, pf;
		raw = In.ar(in, 1).softclip;
		cross = CrossoverDistortion.ar(raw, 0.5, 0.5);
		pf = PeakFollower.ar(raw, decay);
		Out.ar(out, ((1 - distort) * raw) + (distort * pf * cross));
	}
).play(s, [\in, ~usbinput, \out, ~recordb, \distort, 0 ]);

// ~decimator = SynthDef(
// 	\decimator,
// 	{
// 		arg in=2, out=4, modb, rate=10000, smooth=0.5;
// 		var raw, mod, decimated;
// 		raw = In.ar(in, 1);
// 		mod = In.kr      (modb, 1);
// 		decimated = SmoothDecimator.ar(raw, rate + (0.2 * rate * mod), smooth);
// 		Out.ar(out, decimated);
// 	}
// ).play(s, [\in, ~usbinput, \out, ~recordb, \modb, ~lfob, \rate, 10000 ]);
//

// ~localmax = SynthDef(
// 	\localmax,
// 	{
// 		arg in=2, out=4, threshold=25;
// 		var chain;
// 		chain = FFT(LocalBuf(2048), In.ar(in, 1).distort);
// 		chain = PV_LocalMax(chain, threshold);
// 		Out.ar(out, IFFT.ar(chain));
// 	}
// ).play(s, [\in, ~usbinput, \out, ~recordb, \threshold, 25 ]);
//

// ~scramble = SynthDef(
// 	\scramble,
// 	{
// 		arg in=2, out=4, shift=1;
// 		var chain;
// 		chain = FFT(LocalBuf(2048), In.ar(in, 1).distort);
// 		chain = PV_BinScramble(chain, 0.5, 0.2, Impulse.kr(shift));
// 		Out.ar(out, IFFT.ar(chain));
// 	}
// ).play(s, [\in, ~usbinput, \out, ~recordb, \shift, 1 ]);
//


)