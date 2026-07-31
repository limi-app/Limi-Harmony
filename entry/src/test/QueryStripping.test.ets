import { describe, expect, it } from '@ohos/hypium';
import { parseQueryStrippingRecords, processQueryStripping } from '../main/ets/logic/rules/cloud/firefox/QueryStripping';

export default function queryStrippingTest() {
  describe('QueryStrippingTest', () => {
    it('parseRecordsMergesStripListAndAllowList', 0, () => {
      const body = `{
        "data": [
          {"schema":1,"allowList":["googleadservices.com"],"stripList":[],"id":"a","last_modified":100},
          {"schema":2,"allowList":[],"stripList":["gclid","dclid"],"id":"b","last_modified":200},
          {"schema":3,"allowList":[],"stripList":["fbclid","mkt_tok"],"id":"c","last_modified":300}
        ]
      }`;
      const data = parseQueryStrippingRecords(body);
      expect(data.stripList).assertDeepEquals(['gclid', 'dclid', 'fbclid', 'mkt_tok']);
      expect(data.allowList).assertDeepEquals(['googleadservices.com']);
      expect(data.lastModified).assertEqual(300);
    });

    it('stripParamsFromStripList', 0, () => {
      const result = processQueryStripping('https://example.com/?gclid=123&fbclid=abc&foo=bar', ['gclid', 'fbclid'], []);
      expect(result).assertEqual('https://example.com/?foo=bar');
    });

    it('keepUrlUnchangedWhenHostInAllowList', 0, () => {
      const result = processQueryStripping('https://googleadservices.com/?gclid=123', ['gclid'], ['googleadservices.com']);
      expect(result).assertEqual('https://googleadservices.com/?gclid=123');
    });

    it('keepUrlUnchangedWhenNoMatchingParams', 0, () => {
      const result = processQueryStripping('https://example.com/?foo=bar', ['gclid'], []);
      expect(result).assertEqual('https://example.com/?foo=bar');
    });
  });
}
