import { types as T, ok, error, guardDurationAboveMinimum, catchError } from "../deps.ts";

export const health: T.ExpectedExports.health = {
  // Checks that the server is running and reachable via http
  // deno-lint-ignore require-await
  async "webui"(effects, duration) {
	  const errorValue = guardDurationAboveMinimum({ duration, minimumTime: 30_000 });
		if (errorValue) {
			return errorValue;
		}

		const url = "http://stable-diffusion-webui.embassy:7860";
    return await effects.fetch(url)
      .then((_) => ok)
      .catch((e) => error(`Can not reach webserver.`));
  },
};
