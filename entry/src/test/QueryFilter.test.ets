import { describe, expect, it } from '@ohos/hypium';
import { BraveQueryRule } from '../main/ets/logic/rules/cloud/brave/QueryRules';
import { processQueryFilter } from '../main/ets/logic/rules/cloud/brave/QueryFilter';

export default function queryFilterTest() {
  describe('QueryFilterTest', () => {
    it('stripGlobalParams', 0, () => {
      const rules: BraveQueryRule[] = [
        BraveQueryRule.fromJson({
          include: ['*://*/*'],
          params: ['fbclid', 'gclid'],
        }),
      ];
      const result = processQueryFilter('https://example.com/?fbclid=1&gclid=2&keep=1', rules);
      expect(result).assertEqual('https://example.com/?keep=1');
    });

    it('siteSpecificOverride', 0, () => {
      const rules: BraveQueryRule[] = [
        BraveQueryRule.fromJson({
          include: ['*://*/*'],
          params: ['fbclid'],
        }),
        BraveQueryRule.fromJson({
          include: ['*://*.youtube.com/*', '*://*.youtu.be/*'],
          params: ['si'],
        }),
      ];
      const result = processQueryFilter('https://www.youtube.com/watch?v=abc&si=xyz&fbclid=1', rules);
      expect(result).assertEqual('https://www.youtube.com/watch?v=abc');
    });
  });
}
