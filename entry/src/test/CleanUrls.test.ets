import { describe, expect, it } from '@ohos/hypium';
import { BraveQueryRule } from '../main/ets/logic/rules/cloud/brave/QueryRules';
import { processCleanUrls } from '../main/ets/logic/rules/cloud/brave/CleanUrls';

export default function cleanUrlsTest() {
  describe('CleanUrlsTest', () => {
    it('stripSiteSpecificParams', 0, () => {
      const rules: BraveQueryRule[] = [
        BraveQueryRule.fromJson({
          include: ['*://*.amazon.com/*'],
          params: ['ref', 'tag'],
        }),
      ];
      const result = processCleanUrls('https://www.amazon.com/dp/123?ref=abc&tag=xyz&keep=1', rules);
      expect(result).assertEqual('https://www.amazon.com/dp/123?keep=1');
    });

    it('skipNonMatchingHost', 0, () => {
      const rules: BraveQueryRule[] = [
        BraveQueryRule.fromJson({
          include: ['*://*.amazon.com/*'],
          params: ['ref'],
        }),
      ];
      const result = processCleanUrls('https://example.com/?ref=abc', rules);
      expect(result).assertEqual('https://example.com/?ref=abc');
    });

    it('respectExclude', 0, () => {
      const rules: BraveQueryRule[] = [
        BraveQueryRule.fromJson({
          include: ['*://*/*'],
          exclude: ['https://app.hive.co/*'],
          params: ['h_sid'],
        }),
      ];
      const excluded = processCleanUrls('https://app.hive.co/page?h_sid=1', rules);
      expect(excluded).assertEqual('https://app.hive.co/page?h_sid=1');
      const included = processCleanUrls('https://example.com/page?h_sid=1', rules);
      expect(included).assertEqual('https://example.com/page');
    });

    it('cumulativeAcrossRules', 0, () => {
      const rules: BraveQueryRule[] = [
        BraveQueryRule.fromJson({
          include: ['*://*.amazon.com/*'],
          params: ['ref'],
        }),
        BraveQueryRule.fromJson({
          include: ['*://*/*'],
          params: ['gclid'],
        }),
      ];
      const result = processCleanUrls('https://www.amazon.com/dp/1?ref=abc&gclid=xyz&keep=1', rules);
      expect(result).assertEqual('https://www.amazon.com/dp/1?keep=1');
    });
  });
}
