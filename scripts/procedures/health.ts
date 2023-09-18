import { types as T, ok, error, errorCode, guardDurationAboveMinimum, catchError } from "../deps.ts";

export const health: T.ExpectedExports.health = {
  // Checks that the server is running and reachable via http
  // deno-lint-ignore require-await
  async "webui"(effects, duration) {
		const url = "http://stable-diffusion-webui.embassy:7860";
		const statusurl = "http://stable-diffusion-webui.embassy:7850";
		try {
    	return await effects.fetch(url).then((_) => ok);
		} catch(e) {
    	if (await effects.fetch(statusurl).then((_) => true).catch((_) => false)) {
				return errorCode(61, 'Webserver will start after downloading')
			}
		  const guardvalue = guardDurationAboveMinimum({ duration, minimumTime: 60_000 });
			if (guardvalue) {
				return guardvalue;
			}
			return error(`Can not reach webserver`);
		}
  },
};
