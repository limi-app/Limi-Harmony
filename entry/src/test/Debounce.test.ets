import { describe, expect, it } from '@ohos/hypium';
import { DebounceRule } from '../main/ets/logic/rules/cloud/brave/Debounce';
import { processDebounce } from '../main/ets/logic/rules/cloud/brave/Debounce';

export default function debounceTest() {
  describe('DebounceTest', () => {
    it('redirectParam', 0, () => {
      const rules: DebounceRule[] = [
        DebounceRule.fromJson({
          include: ['*://go.skimresources.com/*'],
          action: 'redirect',
          param: 'url',
        }),
      ];
      const result = processDebounce(
        'https://go.skimresources.com/?url=https%3A%2F%2Fexample.com%2Fpage%3Futm_source%3Dx',
        rules,
      );
      expect(result).assertEqual('https://example.com/page?utm_source=x');
    });

    it('noRedirectWhenParamMissing', 0, () => {
      const rules: DebounceRule[] = [
        DebounceRule.fromJson({
          include: ['*://go.skimresources.com/*'],
          action: 'redirect',
          param: 'url',
        }),
      ];
      const result = processDebounce('https://go.skimresources.com/?id=1', rules);
      expect(result).assertNull();
    });

    it('skipNonMatchingHost', 0, () => {
      const rules: DebounceRule[] = [
        DebounceRule.fromJson({
          include: ['*://go.skimresources.com/*'],
          action: 'redirect',
          param: 'url',
        }),
      ];
      const result = processDebounce('https://example.com/?url=https%3A%2F%2Ftarget.com', rules);
      expect(result).assertNull();
    });

    it('regexPathAmp', 0, () => {
      const rules: DebounceRule[] = [
        DebounceRule.fromJson({
          include: ['*://*.cdn.ampproject.org/c/s/*'],
          prepend_scheme: 'https',
          action: 'regex-path',
          param: '^/c/s/(.*)$',
        }),
      ];
      const result = processDebounce(
        'https://example-com.cdn.ampproject.org/c/s/example.com/article?id=1',
        rules,
      );
      expect(result).assertEqual('https://example.com/article?id=1');
    });

    it('regexPathTemplate', 0, () => {
      const rules: DebounceRule[] = [
        DebounceRule.fromJson({
          include: ['*://y2u.be/*'],
          action: 'regex-path-template',
          param: '^/([^/]+)$',
          redirect_url_template: 'https://www.youtube.com/watch?v=$1',
        }),
      ];
      const result = processDebounce('https://y2u.be/abc123', rules);
      expect(result).assertEqual('https://www.youtube.com/watch?v=abc123');
    });

    it('base64Redirect', 0, () => {
      const rules: DebounceRule[] = [
        DebounceRule.fromJson({
          include: ['*://*.ouo.today/*'],
          action: 'base64,redirect',
          param: 'cr',
        }),
      ];
      const result = processDebounce('https://ouo.today/x?cr=aHR0cHM6Ly9leGFtcGxlLmNvbS9wYWdl', rules);
      expect(result).assertEqual('https://example.com/page');
    });

    it('base64RedirectUrlSafeUnpadded', 0, () => {
      const rules: DebounceRule[] = [
        DebounceRule.fromJson({
          include: ['*://*.ouo.today/*'],
          action: 'base64,redirect',
          param: 'cr',
        }),
      ];
      const result = processDebounce(
        'https://ouo.today/x?cr=aHR0cHM6Ly9leGFtcGxlLmNvbS8_a2V5PXZhbHVlJmZvbz1iYXI',
        rules,
      );
      expect(result).assertEqual('https://example.com/?key=value&foo=bar');
    });
  });
}
