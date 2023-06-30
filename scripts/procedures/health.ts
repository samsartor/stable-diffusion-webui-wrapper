import { types as T, checkWebUrl, catchError } from "../deps.ts";

export const health: T.ExpectedExports.health = {
  // deno-lint-ignore require-await
  async "webui"(effects, duration) {
    // Checks that the server is running and reachable via http
    return checkWebUrl("http://stable-diffusion-webui.embassy:80")(effects, duration).catch(catchError(effects))
  },
};
