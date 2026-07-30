import { describe, expect, it } from '@ohos/hypium';
import { processUTMParams } from '../main/ets/logic/rules/common/CommonParams';

function parseQueryParams(url: string): Record<string, string[]> {
  const qIdx = url.indexOf('?');
  if (qIdx < 0) {
    return {};
  }
  const query = url.substring(qIdx + 1);
  const params: Record<string, string[]> = {};
  const pairs = query.split('&');
  for (const pair of pairs) {
    const eqIdx = pair.indexOf('=');
    const key = eqIdx >= 0 ? pair.substring(0, eqIdx) : pair;
    const value = eqIdx >= 0 ? pair.substring(eqIdx + 1) : '';
    if (!params[key]) {
      params[key] = [];
    }
    params[key].push(value);
  }
  return params;
}

export default function utmParamsTest() {
  describe('UTMParamsTest', () => {
    it('removeAllUTMParameters', 0, () => {
      const result = processUTMParams(
        'https://example.com/?utm_source=google&utm_medium=cpc&utm_campaign=summer_sale&utm_term=running+shoes&utm_content=logolink'
      );
      const params = parseQueryParams(result);
      expect(result).assertEqual('https://example.com/');
      expect(Object.keys(params).length).assertEqual(0);
    });

    it('keepNonUTMParameters', 0, () => {
      const result = processUTMParams(
        'https://example.com/?param1=value1&utm_source=google&param2=value2'
      );
      const params = parseQueryParams(result);
      expect(Object.keys(params).length).assertEqual(2);
      expect(params['param1'][0]).assertEqual('value1');
      expect(params['param2'][0]).assertEqual('value2');
      expect(params['utm_source']).assertUndefined();
    });

    it('keepUrlUnchangedWhenNoUTMParameters', 0, () => {
      const originalUrl = 'https://example.com/?param1=value1&param2=value2';
      const result = processUTMParams(originalUrl);
      const params = parseQueryParams(result);
      expect(result).assertEqual(originalUrl);
      expect(params['param1'][0]).assertEqual('value1');
      expect(params['param2'][0]).assertEqual('value2');
    });

    it('removePartialUTMParameters', 0, () => {
      const result = processUTMParams('https://example.com/?utm_source=google&param1=value1');
      const params = parseQueryParams(result);
      expect(result).assertEqual('https://example.com/?param1=value1');
      expect(params['utm_source']).assertUndefined();
      expect(params['param1'][0]).assertEqual('value1');
    });

    it('handleEmptyParameters', 0, () => {
      const originalUrl = 'https://example.com/';
      const result = processUTMParams(originalUrl);
      const params = parseQueryParams(result);
      expect(result).assertEqual(originalUrl);
      expect(Object.keys(params).length).assertEqual(0);
    });

    it('handleMultipleValuesParameter', 0, () => {
      const result = processUTMParams(
        'https://example.com/?param1=value1&param1=value2&utm_source=google'
      );
      const params = parseQueryParams(result);
      expect(params['utm_source']).assertUndefined();
      expect(params['param1'] !== undefined && params['param1'] !== null).assertTrue();
      expect(params['param1'].length).assertEqual(2);
    });
  });
}
