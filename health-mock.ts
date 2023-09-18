const effects = {
	fetch: fetch,
};
const ok = [0, ''];
const errorCode = (code, msg) => [code, msg];
const error = (msg) => [60, msg];
const guardDurationAboveMinimum = (x) => [-1, 'guard'];

const url = 'http://localhost:7860';
const statusurl = 'http://localhost:7850';

const health = {
};

for (const func of health) {
	func(effects, 0).then(console.log);
}