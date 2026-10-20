// Every character the export makes, and how (§21.3, §21.6, §21.9).
//
//   module   the design's file in art/design/creatures/
//   res      the sculpt step the body is meshed at before it is decimated
//            (finer keeps thin parts; the paint is baked from the field, so it
//            does not depend on this)
//   body     the body's triangle budget after decimation
//   seg      the cap on the accessories' primitive segments (three-lod.js)
//   tex      the atlas size
//   height   §21.6's height in metres; when `fix` is set the model is scaled to
//            it (by the body without plumes), otherwise the module's GAME_SCALE
//            stands and the height is only checked. Sages: §21.1's "about
//            1.5 m"; the Archivist is "tall", the Tinkerer "small" (§21.6)
//   school   the school its colour belongs to (§21.2)
//   group    the order of §21.9's launch list
export const KINDS = {
	// The eighteen ruleborn.
	featherkin: { module: 'featherkin.js', res: 0.0095, body: 2600, seg: 0.3, height: 0.6, school: 'motion', group: 'ruleborn' },
	skyskipper: { module: 'skyskipper-rig.js', family: 'skyskipper', res: 0.0078, body: 2800, seg: 0.3, height: 0.8, fix: true, school: 'motion', group: 'ruleborn' },
	rambler: { module: 'rambler.js', res: 0.009, body: 3200, seg: 0.35, height: 0.9, school: 'motion', group: 'ruleborn' },
	glassgolem: { module: 'glassgolem.js', res: 0.0095, body: 2400, seg: 0.4, height: 1.2, fix: true, school: 'matter', group: 'ruleborn' },
	quarryback: { module: 'quarryback.js', res: 0.009, body: 3400, seg: 0.4, height: 0.9, school: 'matter', group: 'ruleborn' },
	prismmite: { module: 'prismmite.js', res: 0.006, body: 3000, seg: 0.4, height: 0.5, fix: true, school: 'matter', group: 'ruleborn' },
	tidewalker: { module: 'tidewalker.js', res: 0.0075, body: 2800, seg: 0.3, height: 0.8, school: 'time', group: 'ruleborn' },
	hourkeeper: { module: 'hourkeeper.js', res: 0.008, body: 3000, seg: 0.35, height: 0.9, school: 'time', group: 'ruleborn' },
	stillwatch: { module: 'stillwatch.js', res: 0.008, body: 3200, seg: 0.4, height: 1.2, school: 'time', group: 'ruleborn' },
	emberling: { module: 'emberling.js', res: 0.0065, body: 2800, seg: 0.3, height: 0.7, school: 'energy', group: 'ruleborn' },
	stormhound: { module: 'stormhound.js', res: 0.0075, body: 3400, seg: 0.4, height: 0.9, school: 'energy', group: 'ruleborn' },
	sparkwright: { module: 'sparkwright.js', res: 0.007, body: 2800, seg: 0.3, height: 0.8, school: 'energy', group: 'ruleborn' },
	mossbear: { module: 'mossbear.js', res: 0.011, body: 3000, seg: 0.25, height: 1.4, school: 'life', group: 'ruleborn' },
	bloomling: { module: 'bloomling.js', res: 0.006, body: 2800, seg: 0.35, height: 0.6, school: 'life', group: 'ruleborn' },
	rootrunner: { module: 'rootrunner.js', res: 0.007, body: 3000, seg: 0.35, height: 0.8, school: 'life', group: 'ruleborn' },
	echoplate: { module: 'echoplate.js', res: 0.011, body: 3200, seg: 0.4, height: 1.2, school: 'spirit', group: 'ruleborn' },
	lanternwisp: { module: 'lanternwisp.js', res: 0.006, body: 3000, seg: 0.35, height: 0.6, fix: true, school: 'spirit', group: 'ruleborn' },
	soulmender: { module: 'soulmender.js', res: 0.007, body: 3000, seg: 0.35, height: 0.9, school: 'spirit', group: 'ruleborn' },
	// The four launch Sages.
	archivist: { module: 'archivist-rig.js', family: 'archivist', res: 0.0078, body: 3400, seg: 0.3, height: 1.6, fix: true, school: 'sage', group: 'sage' },
	tinkerer: { module: 'tinkerer.js', res: 0.011, body: 2800, seg: 0.3, height: 1.2, fix: true, school: 'sage', group: 'sage' },
	gardener: { module: 'gardener.js', res: 0.011, body: 2800, seg: 0.25, height: 1.55, fix: true, school: 'sage', group: 'sage' },
	wanderer: { module: 'wanderer.js', res: 0.011, body: 3000, seg: 0.3, height: 1.5, fix: true, school: 'sage', group: 'sage' },
	// Visitors and paradox-born.
	cartographer: { module: 'cartographer.js', res: 0.007, body: 2800, seg: 0.3, height: 1.66, school: 'visitor', group: 'visitor' },
	collector: { module: 'collector.js', res: 0.007, body: 3000, seg: 0.3, height: 0.97, school: 'visitor', group: 'visitor' },
	stray: { module: 'stray.js', res: 0.0065, body: 3000, seg: 0.35, height: 0.56, school: 'visitor', group: 'visitor' },
	reverser: { module: 'reverser.js', res: 0.007, body: 3200, seg: 0.4, height: 0.9, school: 'paradox', group: 'paradox' },
	twinned: { module: 'twinned.js', res: 0.0065, body: 3600, seg: 0.4, height: 0.8, school: 'paradox', group: 'paradox' },
	unmade: { module: 'unmade.js', res: 0.006, body: 3400, seg: 0.4, height: 0.84, school: 'paradox', group: 'paradox' },
	// The rest: Sages after launch, anomalies, law creatures, wildlife.
	chronicler: { module: 'chronicler.js', res: 0.011, body: 3000, seg: 0.3, height: 1.5, fix: true, school: 'sage', group: 'sage' },
	lamplighter: { module: 'lamplighter.js', res: 0.011, body: 3000, seg: 0.3, height: 1.45, fix: true, school: 'sage', group: 'sage' },
	devourer: { module: 'devourer.js', res: 0.008, body: 3400, seg: 0.35, height: 1.92, fix: true, school: 'anomaly', group: 'anomaly' },
	hourglassstorm: { module: 'hourglassstorm.js', res: 0.008, body: 3400, seg: 0.35, height: 1.93, fix: true, school: 'anomaly', group: 'anomaly' },
	wildfirebloom: { module: 'wildfirebloom.js', res: 0.0075, body: 3200, seg: 0.3, height: 1.87, fix: true, school: 'anomaly', group: 'anomaly' },
	illusoryguard: { module: 'illusoryguard.js', family: 'illusory', res: 0.0095, body: 2600, seg: 0.3, height: 0.6, school: 'law', group: 'law' },
	swarmling: { module: 'swarmling.js', res: 0.005, body: 2000, seg: 0.35, height: 0.36, school: 'law', group: 'law' },
	skyjelly: { module: 'skyjelly.js', res: 0.006, body: 2400, seg: 0.35, height: 0.65, fix: true, school: 'wildlife', group: 'wildlife' },
	lanternfish: { module: 'lanternfish.js', res: 0.0055, body: 2000, seg: 0.35, height: 0.39, fix: true, school: 'wildlife', group: 'wildlife' },
	prismbeetle: { module: 'prismbeetle.js', res: 0.005, body: 2000, seg: 0.35, height: 0.38, school: 'wildlife', group: 'wildlife' },
	puffballflock: { module: 'puffballflock.js', family: 'shared', res: 0.0065, body: 2600, seg: 0.35, height: 0.47, school: 'wildlife', group: 'wildlife' },
	puffbee: { module: 'puffbee.js', family: 'shared', res: 0.0065, body: 2600, seg: 0.35, height: 0.57, school: 'wildlife', group: 'wildlife' },
	ashmoth: { module: 'ashmoth.js', family: 'shared', res: 0.005, body: 1600, seg: 0.35, height: 0.4, fix: true, school: 'wildlife', group: 'wildlife' },
	lanternmoth: { module: 'lanternmoth.js', family: 'shared', res: 0.005, body: 1600, seg: 0.35, height: 0.32, fix: true, school: 'wildlife', group: 'wildlife' },
	valemoth: { module: 'valemoth.js', family: 'shared', res: 0.005, body: 1600, seg: 0.35, height: 0.34, fix: true, school: 'wildlife', group: 'wildlife' },
};

// §21.3: "characters 3,000 to 6,000 triangles".
export const MAX_TRIS = 6000;
