import { describe, expect, it } from '@ohos/hypium';
import { UrlPattern } from '../main/ets/logic/rules/cloud/brave/UrlPattern';
import { parseUrl } from '../main/ets/utils/LinkExtractor';

export default function urlPatternTest() {
  describe('UrlPatternTest', () => {
    it('matchExactHost', 0, () => {
      const parsed = parseUrl('https://example.com/path?a=1');
      expect(parsed !== null).assertTrue();
      if (parsed !== null) {
        expect(UrlPattern.compile('*://example.com/*').matches(parsed)).assertTrue();
        expect(UrlPattern.compile('https://example.com/*').matches(parsed)).assertTrue();
        expect(UrlPattern.compile('http://example.com/*').matches(parsed)).assertFalse();
        expect(UrlPattern.compile('*://example.org/*').matches(parsed)).assertFalse();
      }
    });

    it('matchSubdomainWildcard', 0, () => {
      const parsed = parseUrl('https://www.facebook.com/page');
      expect(parsed !== null).assertTrue();
      if (parsed !== null) {
        // `*.facebook.com` 匹配子域名与裸域名
        expect(UrlPattern.compile('*://*.facebook.com/*').matches(parsed)).assertTrue();
        // `facebook.com`（无 *. 前缀）是精确 host 匹配，不匹配子域名
        expect(UrlPattern.compile('*://facebook.com/*').matches(parsed)).assertFalse();
        expect(UrlPattern.compile('*://*.facebooks.com/*').matches(parsed)).assertFalse();
      }
    });

    it('matchAnyHost', 0, () => {
      const parsed = parseUrl('https://foo.example.com/x');
      expect(parsed !== null).assertTrue();
      if (parsed !== null) {
        expect(UrlPattern.compile('*://*/*').matches(parsed)).assertTrue();
      }
    });

    it('matchPathWithQuery', 0, () => {
      const parsed = parseUrl('https://www.google.com/search?q=hello&source=web');
      expect(parsed !== null).assertTrue();
      if (parsed !== null) {
        expect(UrlPattern.compile('*://www.google.com/search?*').matches(parsed)).assertTrue();
        expect(UrlPattern.compile('*://www.google.com/maps?*').matches(parsed)).assertFalse();
      }
    });

    it('matchPathWildcardSegment', 0, () => {
      const parsed = parseUrl('https://ctr.narvar.com/v2/tracking/123');
      expect(parsed !== null).assertTrue();
      if (parsed !== null) {
        expect(UrlPattern.compile('*://ctr.narvar.com/*/tracking/*').matches(parsed)).assertTrue();
      }
    });

    it('excludePatterns', 0, () => {
      const parsed = parseUrl('https://www.x.com/i/redirect?url=x');
      expect(parsed !== null).assertTrue();
      if (parsed !== null) {
        expect(UrlPattern.compile('*://*.x.com/*').matches(parsed)).assertTrue();
        expect(UrlPattern.compile('*://*.x.com/i/redirect?*').matches(parsed)).assertTrue();
      }
    });
  });
}
