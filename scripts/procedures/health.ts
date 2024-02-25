import { types as T, ok, error, errorCode, guardDurationAboveMinimum } from '../deps.ts';

const url = 'http://stable-diffusion-webui.embassy:7860';
const statusurl = 'http://stable-diffusion-webui.embassy:7850';

type Status = {
  'state': 'PROGRESS' | 'ERROR' | 'OK',
  'message': string | null,
  'done': string | null,
};

export const health: T.ExpectedExports.health = {
  // Checks that the server is running and reachable via http
  async 'webui'(effects, duration) {
    try {
      await effects.fetch(url);
      return ok;
    } catch(e) { console.warn(e) }
    try {
      const status = <Status> await (await effects.fetch(statusurl)).json();
      if (status['state'] == 'PROGRESS') {
        return errorCode(61, 'Webserver will start after downloading');
      }
      if (status['state'] == 'OK') {
        const waiting = Date.now() - Date.parse(status['done']!);
        if (waiting < 30_000) {
          return errorCode(61, 'Webserver starting');
        } else {
          return error('Can not reach webserver');
        }
      }
      if (status['state'] == 'ERROR') {
        return errorCode(60, 'Can not start webserver without default models');
      }
    } catch(e) { console.warn(e) }
    const value = guardDurationAboveMinimum({ duration, minimumTime: 30_000 });
    if (value) {
      return value;
    } else {
      return error('Can not reach service');
    }
  },
  // Checks if a model is downloading
  async 'download'(effects, duration) {
    try {
      const status = <Status> await (await effects.fetch(statusurl)).json();
      if (status['state'] == 'OK') {
        return ok;
      }
      if (status['state'] == 'PROGRESS') {
        return errorCode(61, status['message'] || 'Downloading default checkpoint');
      }
      if (status['state'] == 'ERROR') {
        return errorCode(60, status['message'] || 'Unknown error');
      }
    } catch(e) { console.warn(e); }
    const value = guardDurationAboveMinimum({ duration, minimumTime: 30_000 });
    if (value) {
      return value;
    } else {
      return error('Can not reach service');
    }
  },
};
